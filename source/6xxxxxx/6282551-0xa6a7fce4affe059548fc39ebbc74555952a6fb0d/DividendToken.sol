pragma solidity ^0.4.24;

import './Administratable.sol';
import './Pausable.sol';
import './StandardToken.sol';
import './SafeMath.sol';

contract DividendToken is StandardToken, Pausable, Administratable {
  using SafeMath for uint256;

  uint256 public period = 0;
  uint256 public buyBackTime;
  bool public ended = false;
  
  mapping (uint256 => uint256) public dividends;
  mapping (uint256 => uint256) public dividendDates;
  uint256 public buyBackTotal;
  mapping (address => bool) public boughtBack;
  
  mapping (address => mapping (uint256 => uint256)) internal holdings;
  mapping (address => uint256) internal last;
  mapping (address => uint256) public claimedTo;
  mapping (address => bool) beenDivLocked;
  mapping (address => uint256[]) divLocks;

  mapping(uint256 => uint256) totalAt;

  modifier canBuyBack() {
    require(now > buyBackTime);
    _;
  }

  modifier onlyLive() {
    require(!ended);
    _;
  }

  function updateHoldings(address _holder) internal returns (bool success) {
    uint256 lastPeriod = last[_holder];
    uint256 lastAmount = holdings[_holder][lastPeriod];
    if(lastAmount != 0) {
      for (uint i = lastPeriod + 1; i <= period; i++) {
        holdings[_holder][i] = lastAmount;
      }
    }
    last[_holder] = period;
    return true;
  }

  function updateHoldingsTo(address _holder, uint256 _to) public onlyAdmin returns (bool success){
    require(_to > last[_holder]);
    require(_to <= period);
    uint256 lastPeriod = last[_holder];
    uint256 lastAmount = holdings[_holder][lastPeriod];
    if(lastAmount != 0) {
      for (uint i = lastPeriod + 1; i <= _to; i++) {
        holdings[_holder][i] = lastAmount;
      }
    }
    last[_holder] = _to;
    return true;
  }
  
  function lockedAt(address _address, uint256 _period) public view returns (bool) {
    if(!beenDivLocked[_address]) {
      return false;
    }
    bool locked = false;
    for(uint i = 0; i < divLocks[_address].length; i++) {
      if(divLocks[_address][i] > _period) {
        break;
      } 
      locked = !locked;
    }
    return locked;
  }

  function addLock(address _locked) onlyOwner public returns (bool success) {
    require(!lockedAt(_locked, period));
    if (last[_locked] < period) {
      updateHoldings(_locked);
    }
    totalAt[period] = totalAt[period].sub(balanceOf(_locked));
    beenDivLocked[_locked] = true;
    divLocks[_locked].push(period);
    emit Locked(_locked, period);
    return true;
  }

  function revokeLock(address _unlocked) onlyOwner public returns (bool success) {
    require(lockedAt(_unlocked, period));
    if (last[_unlocked] < period) {
      updateHoldings(_unlocked);
    }
    totalAt[period] = totalAt[period].add(balanceOf(_unlocked));
    divLocks[_unlocked].push(period);
    emit Unlocked(_unlocked, period);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    if(ended) {
      return 0;
    }
    return holdings[_owner][last[_owner]];
  }

  function transfer(address _to, uint256 _value) onlyLive whenNotPaused public returns (bool) {
    require(_to != address(0));
    uint256 senderLastPeriod = last[msg.sender];
    require(_value <= holdings[msg.sender][senderLastPeriod]);

    if (senderLastPeriod < period) {
      updateHoldings(msg.sender);
    }

    if (last[_to] < period) {
      updateHoldings(_to);
    }

    holdings[msg.sender][period] = holdings[msg.sender][period].sub(_value);
    holdings[_to][period] = holdings[_to][period].add(_value);
    bool fromLocked = lockedAt(msg.sender, period);
    bool toLocked = lockedAt(_to, period);
    if(fromLocked && !toLocked) {
      totalAt[period] = totalAt[period].add(_value);
    } else if(!fromLocked && toLocked) {
      totalAt[period] = totalAt[period].sub(_value);
    }
    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) onlyLive whenNotPaused public returns (bool) {
    require(_to != address(0));
    uint256 senderLastPeriod = last[_from];
    require(_value <= holdings[_from][senderLastPeriod]);
    require(_value <= allowed[_from][msg.sender]);

     if (senderLastPeriod < period) {
       updateHoldings(_from);
    }

    if (last[_to] < period) {
      updateHoldings(_to);
    }

    holdings[_from][period] = holdings[_from][period].sub(_value);
    holdings[_to][period] = holdings[_to][period].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    bool fromLocked = lockedAt(_from, period);
    bool toLocked = lockedAt(_to, period);
    if(fromLocked && !toLocked) {
      totalAt[period] = totalAt[period].add(_value);
    } else if(!fromLocked && toLocked) {
      totalAt[period] = totalAt[period].sub(_value);
    }
    emit Transfer(_from, _to, _value);

    return true;
  }

  function () public onlyAdmin onlyLive payable {
    payIn();
  }

  function payIn() public onlyLive onlyAdmin payable returns (bool) {
    dividends[period] = msg.value;
    dividendDates[period] = now;
    period = period.add(1);
    totalAt[period] = totalAt[period.sub(1)];
    emit Paid(msg.sender, period.sub(1), msg.value);
    return true;
  }
  
  function claimDividends() whenNotPaused public returns (uint256 amount) {
    require(claimedTo[msg.sender] < period);
    uint256 total = 0;
    if (last[msg.sender] < period) {
      updateHoldings(msg.sender);
    }
    for (uint i = claimedTo[msg.sender]; i < period; i++) {
      if (holdings[msg.sender][i] > 0 && !lockedAt(msg.sender, i)) {
        uint256 multiplier = dividends[i].mul(holdings[msg.sender][i]);
        total += multiplier.div(totalAt[i]);
      }
    }
    claimedTo[msg.sender] = period;
    if(total > 0) {
      msg.sender.transfer(total);
      emit Claimed(msg.sender, i, total);
    }
    return total;
  }

  function claimDividendsFor(address _address) onlyAdmin public returns (uint256 amount) {
    require(claimedTo[_address] < period);
    uint256 total = 0;
    if (last[_address] < period) {
      updateHoldings(_address);
    }
    for (uint i = claimedTo[_address]; i < period; i++) {
      if (holdings[_address][i] > 0 && !lockedAt(_address, i)) {
        uint256 multiplier = dividends[i].mul(holdings[_address][i]);
        total += multiplier.div(totalAt[i]);
      }
    }
    claimedTo[_address] = period;
    if(total > 0) {
      _address.transfer(total);
      emit Claimed(_address, i, total);
    }
    return total;
  }
  
  function outstandingFor(address _address) public view returns (uint256 amount) {
    uint256 total = 0;
    uint256 holds = 0;
    for (uint i = claimedTo[_address]; i < period; i++) {
      if(last[_address] < i) {
        holds = holdings[_address][last[_address]];
      } else {
        holds = holdings[_address][i];
      }
      if (holds > 0 && !lockedAt(_address, i)) {
        uint256 multiplier = dividends[i].mul(holds);
        uint256 owed = multiplier.div(totalAt[i]);
        total += owed;
      }
    }
    return total;
  }

  function outstanding() public view returns (uint256 amount) {
    uint256 total = 0;
    uint256 holds = 0;
    for (uint i = claimedTo[msg.sender]; i < period; i++) {
       if(last[msg.sender] < i) {
        holds = holdings[msg.sender][last[msg.sender]];
      } else {
        holds = holdings[msg.sender][i];
      }
      if (holds > 0 && !lockedAt(msg.sender, i)) {
        uint256 multiplier = dividends[i].mul(holds);
        uint256 owed = multiplier.div(totalAt[i]);
        total += owed;
      }      
    }
    return total;
  }
  
  function buyBack() public onlyAdmin onlyLive canBuyBack payable returns (bool) {
    buyBackTotal = msg.value;
    period += 1;
    emit Paid(msg.sender, period - 1, msg.value);
    ended = true;
  }

  function claimBuyBack() public returns (bool) {
    require(ended);
    require(!boughtBack[msg.sender]);
    if (last[msg.sender] < period) {
      updateHoldings(msg.sender);
    }
    uint256 multiplier = buyBackTotal.mul(holdings[msg.sender][period]);    
    uint256 owed = multiplier.div(totalAt[period.sub(1)]);
    boughtBack[msg.sender] = true;
    msg.sender.transfer(owed);
  }

  function claimBuyBackFor(address _address) onlyAdmin public returns (bool) {
    require(ended);
    require(!boughtBack[_address]);
    if (last[_address] < period) {
      updateHoldings(_address);
    }
    uint256 multiplier = buyBackTotal.mul(holdings[_address][period]);    
    uint256 owed = multiplier.div(totalAt[period.sub(1)]);
    boughtBack[_address] = true;
    _address.transfer(owed);
  }

  function dividendDateHistory() public view returns (uint256[]) {
    uint256[] memory dates = new uint[](period);
    for(uint i = 0; i < period; i++) {
      dates[i] = dividendDates[i];
    }
    return dates;
  }

  function dividendHistory() public view returns (uint256[]) {
    uint256[] memory divs = new uint[](period);
    for(uint i = 0; i < period; i++) {
      divs[i] = dividends[i];
    }
    return divs;
  }

  function dividendHistoryFor(address _address) public view returns (uint256[]) {
    uint256[] memory divs = new uint[](period);
    for(uint i = 0; i < period; i++) {
      uint256 multiplier;
      if(last[_address] < i) {
        multiplier = dividends[i].mul(holdings[_address][i]);
      } else {
        multiplier = dividends[i].mul(holdings[_address][last[_address]]);
      }
      if(lockedAt(_address, i)) {
        divs[i] = 0;
      } else {
        divs[i] = multiplier.div(totalAt[i]);
      }
    }
    return divs;
  }

  event Paid(address indexed _sender, uint256 indexed _period, uint256 amount);

  event Claimed(address indexed _recipient, uint256 indexed _period, uint256 _amount);

  event Locked(address indexed _locked, uint256 indexed _at);

  event Unlocked(address indexed _unlocked, uint256 indexed _at);
}

