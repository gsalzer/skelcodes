pragma solidity ^0.4.22;
// might need to remove upwards compatibility
import "./SafeMath.sol";

contract Oly {
  using SafeMath for uint256;

  string public constant name = "Etherpoly Dollars"; 
  string public constant symbol = "OLY"; 
  uint8 public constant decimals = 3;

  uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));
  mapping(address => uint256) balances;
  mapping(uint256 => uint256) lastUpdate;
  mapping (address => mapping (address => uint256)) internal allowed;
  uint256 public totalSupply_;
  uint256 private dateCreated;
  address private polyAddress;

   constructor (address _polyAddress) public {
    polyAddress = _polyAddress;
    dateCreated = now - 2 hours;
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }


    modifier onlyPayloadSize(uint size) {
    assert(msg.data.length >= size * 32 + 4);
    _;
  }

    modifier onlyPoly() {
    require (msg.sender == polyAddress);
    _;
  }

 
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);



  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

 
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }




  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public onlyPayloadSize(2) returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public onlyPayloadSize(2) returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  // functions that are interacting with POLY721

  function polyUpdateRevenues(address _tokenOwner, uint256 _tokenId, uint256 _revenues) external onlyPoly() returns (uint256) {
    require(_tokenOwner != address(0));
    require (_revenues > 0);

    // time passed in hours since the last update, or since contract creation if first update
    if (lastUpdate[_tokenId] > 0) {
      uint256 _timePassed = now - lastUpdate[_tokenId];
      _timePassed /= 3600;
    }
    else { 
      _timePassed = now - dateCreated;
      _timePassed /= 3600;
    }

    // if timepassed is higher than one hour, we can calculate hourly revenues, making sure there's no bug
    if (_timePassed >= 1 && _timePassed < 100000) {
      // minting the revenues for the owner of the Token ID, based on the hourly _revenues calculated by POLY721 since _timePassed 
      uint256 _cumulatedRevenues = _revenues * _timePassed; 
      lastUpdate[_tokenId] = now;
      uint256 _newTotalSupply = totalSupply_.add(_cumulatedRevenues);
      uint256 _newBalance = balances[_tokenOwner].add(_cumulatedRevenues);

      totalSupply_ = _newTotalSupply;
      balances[_tokenOwner] = _newBalance;

      emit Transfer(0x0, _tokenOwner, _cumulatedRevenues);
      return _cumulatedRevenues;
      
    } else return 0;

  }


  function polyTransfer(address _from, address _to, uint256 _value) external onlyPoly() {
    //require(_to != address(0));
    require(_from != address(0));
    require(_value <= balances[_from]);
    require (_value > 0);
    // During tests, creator could send coins to itself resulting in throw
    require(_to != _from);

    // SafeMath.sub will throw if there is not enough balance.
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
  }


}

