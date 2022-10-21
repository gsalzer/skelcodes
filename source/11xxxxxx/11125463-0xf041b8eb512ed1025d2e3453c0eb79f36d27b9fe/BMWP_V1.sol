pragma solidity ^0.4.24;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @title BMWP ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/9b3710465583284b8c4c5d2245749246bb2e0094/contracts/token/ERC20/ERC20.sol
 */
contract BMWP is IERC20 {
  /**
   * MATH
   */
  using SafeMath for uint256;

  /**
  * DATA
  */

  // ERC20 BASIC DATA 
  mapping (address => uint256) private _balances;
  string public constant name = "BMWP token"; // solium-disable-line uppercase
  string public constant symbol = "BMWP"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase
  uint256 private _totalSupply;

  // ERC20 DATA
  mapping (address => mapping (address => uint256)) private _allowed;

  // INITIALIZATION DATA
  bool private initialized = false;

  // OWNER DATA
  address public owner;

  /**
  * FUNCTIONALITY
  */

  // INITIALIZATION FUNCTIONALITY

  /**
  * @dev sets initials tokens, the owner.
  * this serves as the constructor for the proxy but compiles to the
  * memory model of the Implementation contract.
  */
  function initialize() public {
    require(!initialized, "already initialized");
    owner = msg.sender;
    initialized = true;
  }

  /**
  * The constructor is used here to ensure that the implementation
  * contract is initialized. An uncontrolled implementation
  * contract might lead to misleading state
  * for users who accidentally interact with it.
  */
  constructor() public {
    initialize();
  }

  // ERC20 BASIC FUNCTIONALITY

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _addr The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _addr) public view returns (uint256) {
    return _balances[_addr];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  // ERC20 FUNCTIONALITY

  /**
  * @dev Function to check the amount of tokens that an owner allowed to a spender.
  * @param _owner address The address which owns the funds.
  * @param spender address The address which will spend the funds.
  * @return A uint256 specifying the amount of tokens still available for the spender.
  */
  function allowance(address _owner, address spender) public view returns (uint256) {
    return _allowed[_owner][spender];
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  // ERC20 FUNCTIONALITY

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  // OWNER FUNCTIONALITY

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner, "onlyOwner");
    _;
  }

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param _newOwner The address to transfer ownership to.
  */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "cannot transfer ownership to address zero");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  /**
  * EVENTS
  */

  // OWNABLE EVENTS
  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  /**
  * @dev Version 1 of the BMWP token .
  * 1. fix the bug that the total quantity is incorrect
  * 2. fix the bug that the token has no holder
  */
  bool private v1_fixed = false;
  function v1Fix() public onlyOwner {
    require(!v1_fixed, "already initialized");
    _totalSupply = 21*10**4*10**18;
    _balances[owner] = _totalSupply;
    v1_fixed = true;
  }
}

