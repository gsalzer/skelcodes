pragma solidity ^0.4.13;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a); 
    return a - b; 
  } 
  
  function add(uint256 a, uint256 b) internal constant returns (uint256) { 
    uint256 c = a + b; assert(c >= a);
    return c;
  }

}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  string message;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
    // SafeMath.sub will throw if there is not enough balance. 
    balances[msg.sender] = balances[msg.sender].sub(_value); 
    balances[_to] = balances[_to].add(_value); 
    Transfer(msg.sender, _to, _value); 
    return true; 
  }

  /** 
   * @dev Gets the balance of the specified address. 
   * @param _owner The address to query the the balance of. 
   * @return An uint256 representing the amount owned by the passed address. 
   */ 
  function balanceOf(address _owner) public constant returns (uint256 balance) { 
    return balances[_owner]; 
  } 
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is BasicToken {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
    totalSupply = 10000000000*10**2;
    balances[owner] = balances[owner].add(totalSupply);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

contract BinaCoin is BasicToken, Ownable {
    
    uint256 order;
    
    string public constant name = "BinaCoin";
    
    string public constant symbol = "BCO";
    
    uint32 public constant decimals = 2;
    
    function transferToken(address _from, address _to, uint256 _value, uint256 _order) onlyOwner public returns (bool) {
    
        order = _order;
        
        require(_from != address(0));
    	require(_to != address(0));
    	require(_value <= balances[_from]);
    
    	balances[_from] = balances[_from].sub(_value);
    	balances[_to] = balances[_to].add(_value);
    
    	Transfer(_from, _to, _value);
    	return true;
    }
    
}
