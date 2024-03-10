pragma solidity ^0.5.17;

library SafeMath
{
  function add(uint256 a, uint256 b) internal pure returns (uint256)
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Variable
{
  string public name;
  string public symbol;
  uint256 public decimals;
  uint256 public totalSupply;
  address public owner;
  address public watchdog;

  uint256 internal _decimals;
  bool internal transferLock;
  
  mapping (address => bool) public blockedAddress;

  mapping (address => uint256) public balanceOf;

  address public newWatchdog;
  address public newOwner;

  constructor() public
  {
    name = "PURIEVER";
    symbol = "PURE";
    decimals = 18;
    _decimals = 10 ** uint256(decimals);
    totalSupply = _decimals * 1200000000;
    transferLock = false;
    owner =  msg.sender;
    balanceOf[owner] = totalSupply;
    watchdog = 0x249b2ABE3d1Edf9A0FCafEB1B8cD04aB9F98f078;
    
    newWatchdog = address(0);
    newOwner = address(0);
  }
}

contract Modifiers is Variable
{

  modifier isOwner
  {
    assert(owner == msg.sender);
    _;
  }

  modifier isValidAddress
  {
    assert(address(0) != msg.sender);
    _;
  }

  modifier isWatchdog
  {
    assert(watchdog == msg.sender);
    _;
  }

  function transferOwnership(address _newOwner) public isWatchdog
  {
      newOwner = _newOwner;
  }

  function transferOwnershipWatchdog(address _newWatchdog) public isOwner
  {
      newWatchdog = _newWatchdog;
  }

  function acceptOwnership() public isOwner
  {
      require(newOwner != address(0));
      owner = newOwner;
      newOwner = address(0);
  }

  function acceptOwnershipWatchdog() public isWatchdog
  {
      require(newWatchdog != address(0));
      watchdog = newWatchdog;
      newWatchdog = address(0);
  }
}

contract Event
{
  event Transfer(address indexed from, address indexed to, uint256 value);
  event TokenBurn(address indexed from, uint256 value);
}

contract manageAddress is Variable, Modifiers, Event
{
  function add_blockedAddress(address _address) public isOwner
  {
    require(_address != owner);
    blockedAddress[_address] = true;
  }
  function delete_blockedAddress(address _address) public isOwner
  {
    blockedAddress[_address] = false;
  }
}
contract Admin is Variable, Modifiers, Event
{
  function admin_tokenBurn(uint256 _value) public isOwner returns(bool success)
  {
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender] -= _value;
    totalSupply -= _value;
    emit TokenBurn(msg.sender, _value);
    return true;
  }
}
contract Get is Variable, Modifiers
{
  function get_transferLock() public view returns(bool)
  {
    return transferLock;
  }
  function get_blockedAddress(address _address) public view returns(bool)
  {
    return blockedAddress[_address];
  }
}

contract Set is Variable, Modifiers, Event
{
  function setTransferLock(bool _transferLock) public isOwner returns(bool success)
  {
    transferLock = _transferLock;
    return true;
  }
}

contract PURE is Variable, Event, Get, Set, manageAddress
{
  using SafeMath for uint256;

  function() external payable 
  {
    revert();
  }
  
  function transfer(address _to, uint256 _value) public isValidAddress
  {
    require(!blockedAddress[msg.sender] && !blockedAddress[_to]);
    require(balanceOf[msg.sender] >= _value && _value > 0);
    require((balanceOf[_to].add(_value)) >= balanceOf[_to] );
    
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
  }
}
