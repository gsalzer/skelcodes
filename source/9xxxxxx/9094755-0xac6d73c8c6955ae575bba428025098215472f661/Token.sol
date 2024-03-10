pragma solidity ^0.5.3;

// ----------------------------------------------------------------------------
// 'CRYPTOBUCKS' Token Contract
//
// Deployed To : 0x4d9ee34b7ee0d3cef04e5909c27a266e7eb14712
// Symbol      : CBUCKS
// Name        : CRYPTOBUCKS
// Total Supply: 1,000,000,000 CBUCKS
// Decimals    : 2
//
// (c) By 'ANONYMOUS' With 'CBUCKS' Symbol 2019.
//
// ----------------------------------------------------------------------------

// Interfaces
import { IERC20Token } from "./iERC20Token.sol";
// Libraries
import { SafeMath } from "./SafeMath.sol";
import { Whitelist } from "./Whitelist.sol";
import { Address } from "./Address.sol";
// Inherited Contracts
import { Pausable } from "./Pausable.sol";

contract Token is IERC20Token, Whitelist, Pausable {
  using SafeMath for uint256;
  using Address for address;

  string _name;
  string _symbol;
  uint256 _totalSupply;
  uint256 _decimals;
  uint256 _burnRate;
  uint256 _totalBurned;

  constructor () public {
    _name = "CRYPTOBUCKS";
    _symbol = "CBUCKS";
    _totalSupply = 100000000000;
    _decimals = 2;
    _burnRate = 100;
    _totalBurned = 0;
    balances[0xE43eBCb96564a6FB3B7A4AbbfD7008b415591b09] = _totalSupply;
    emit Transfer(address(this), 0xE43eBCb96564a6FB3B7A4AbbfD7008b415591b09, _totalSupply);
  }

  mapping(address => uint256) private balances;
  mapping(address => mapping(address => uint256)) private allowed;
  event Burned(address indexed from, uint256 value, uint256 timestamp);
  event BurnRateChanged(address indexed from, uint256 value, uint256 timestamp);

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function decimals() external view returns (uint256) {
    return _decimals;
  }

  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }

  function allowance(address owner, address spender) external view returns (uint256) {
    return allowed[owner][spender];
  }

  function transfer(
    address recipient,
    uint256 amount
    ) external whenNotPaused onlyWhitelisted(msg.sender, recipient) validRecipient(recipient)
    validAmount(amount) validAddress(recipient) sufficientBalance(msg.sender, amount) returns (bool) {
      balances[msg.sender] = balances[msg.sender].sub(amount);
      balances[recipient] = balances[recipient].add(amount);
      burn();
      emit Transfer(msg.sender, recipient, amount);
  }

  function approve(
    address spender,
    uint256 amount
    ) external whenNotPaused validAddress(spender) validRecipient(spender)
    validAmount(amount) sufficientBalance(msg.sender, amount) returns (bool) {
    allowed[msg.sender][spender] = allowed[msg.sender][spender].add(amount);
    emit Approval(msg.sender, spender, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
    ) external whenNotPaused validAddress(recipient) validRecipient(recipient)
    validAmount(amount) sufficientBalance(msg.sender, amount) returns (bool) {
      require(allowed[sender][msg.sender] >= amount, "Above spender allowance.");
      allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(amount);
      balances[recipient] = balances[recipient].add(amount);
      burn();
      emit Transfer(sender, recipient, amount);
    }

  modifier validAddress(address _address) {
    require(_address != address(0), "Cannot send to address 0x0.");
    _;
  }

  modifier validAmount(uint256 _amount) {
    require(_amount > 0, "Amount must be greater than 0.");
    _;
  } 

  modifier sufficientBalance(address _sender, uint256 _amount) {
    require(balances[_sender] >= _amount.add(_burnRate), "Insufficient Funds.");
    _;
  }

  modifier validRecipient(address _address) {
    require(msg.sender != _address, "Cannot send to yourself.");
    _;
  }

  // BURN FUNCTIONALITIES

  function burnRate() external view returns (uint256) {
    return _burnRate;
  }

  function totalBurned() external view returns (uint256) {
    return _totalBurned;
  }

  function burn() internal whenNotPaused returns (bool) {
      balances[msg.sender] = balances[msg.sender].sub(_burnRate);
      _totalSupply = _totalSupply.sub(_burnRate);
      _totalBurned = _totalBurned.add(_burnRate);
      emit Burned(msg.sender, _burnRate, now);
  }

  function changeBurnRate(
    uint256 _amount) external onlyOwner returns (bool) {
      _burnRate = _amount;
      emit BurnRateChanged(msg.sender, _amount, now);
    }
}
