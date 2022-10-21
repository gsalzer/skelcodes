pragma solidity ^0.5.8;

contract SKYNPToken {

  address admin;
  address admin2=0xa4e81224fC73a9E095809e34f5324aa18fA2a412;

  string public name="SkyNavPro";
  string public symbol="SKYNP";
  uint8 public decimals=6;

  uint256 totalSupplyInternal;
  mapping (address => uint256) balances;
  mapping (address => mapping(address => uint256)) allowances;

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
  );

  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );


  constructor (uint256 _initialSupply) public {
    admin=msg.sender;
    totalSupplyInternal = _initialSupply;
    balances[msg.sender]=_initialSupply;
  }

  function totalSupply() public view returns (uint256) {
    return totalSupplyInternal;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowances[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) public returns(bool success){
    require(balances[msg.sender]>=_value, "The balance of the sender is not high enough.");

    balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
    balances[_to]=SafeMath.add(balances[_to], _value);

    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  function approve(address _spender, uint256 _value) public returns(bool success) {

    allowances[msg.sender][_spender]=_value;

    emit Approval(msg.sender, _spender, _value);

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){

    require(balances[_from]>=_value, "The balance of the sender is not high enough.");
    require(allowances[_from][msg.sender]>=_value, "The allowance is not big enough.");

    allowances[_from][msg.sender]=SafeMath.sub(allowances[_from][msg.sender],_value);
    balances[_from]=SafeMath.sub(balances[_from], _value);
    balances[_to]=SafeMath.add(balances[_to],_value);

    emit Transfer(_from, _to, _value);

    return true;
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
