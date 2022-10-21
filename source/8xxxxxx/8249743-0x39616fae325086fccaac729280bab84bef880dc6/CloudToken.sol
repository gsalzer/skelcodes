pragma solidity ^0.5.0;

// import SafeMath for safety checks
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
     function add(uint256 a, uint256 b) internal pure returns (uint256) {
     	uint256 c = a + b;
     	require(c >= a, "SafeMath: addition overflow");

     	return c;
     }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
     	require(b <= a, "SafeMath: subtraction overflow");
     	uint256 c = a - b;

     	return c;
     }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
        	return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
     function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
     	require(b != 0, "SafeMath: modulo by zero");
     	return a % b;
     }
 }

 contract CloudToken {

 	using SafeMath for uint256;

// Public parameters for ERC20 token
uint8 public decimals = 18;
string public name = "Cloud Token";
string public symbol = "CTO";
uint256 public totalSupply= 100000000 *(10**uint256(decimals));

mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;

address public owner;
mapping(address => bool) public blacklist;

// Events that notify clients about token transfer, approval and burn 
event Transfer(address indexed from, address indexed to, uint256 value);
event Burn(address indexed from, uint256 value);
event Approval(address indexed _owner, address indexed _spender, uint256 value);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract and designate ownership
     */
     constructor() public {
     	balanceOf[msg.sender] = totalSupply;
     	owner = msg.sender;
     	emit Transfer(address(0),msg.sender,totalSupply);
     }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */

  function transfer(address _to, uint256 _value) public returns (bool){

  	require(_to != address(0));
  	require(!blacklist[msg.sender] && !blacklist[_to]);
  	require(_value <= balanceOf[msg.sender]);
  	balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
  	balanceOf[_to] = balanceOf[_to].add(_value);
  	emit Transfer(msg.sender, _to, _value);
  	return true;
  }


/**
* Transfer tokens from other address
*
* Send `_value` tokens to `_to` on behalf of `_from`
*
* @param _from The address of the sender
* @param _to The address of the recipient
* @param _value the amount to send 
*/

function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
	
  	require(_to != address(0));
  	require(!blacklist[msg.sender] && !blacklist[_to] && !blacklist[_from]);
	require(_value <= allowance[_from][msg.sender]);
	require(_value <= balanceOf[_from]);
	allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
	balanceOf[_from] = balanceOf[_from].sub(_value);
	balanceOf[_to] = balanceOf[_to].add(_value);
	emit Transfer(_from, _to, _value);
	return true;
}

/**
* @dev Set allowance for other address
*
* Allows `_spender` to spend no more than `_value` tokens on your behalf
*
* @param _spender The address authorized to spend
* @param _value the max amount they can spend

*/
function approve(address _spender, uint256 _value) public returns (bool) {
	require(!blacklist[_spender] && !blacklist[msg.sender]);
	allowance[msg.sender][_spender] = _value;
	emit Approval(msg.sender, _spender, _value);
	return true;
}

/**
* @dev Call this function to burn tokens instead of sending to address(0)

* @param _value amount to burn

*/
function burn(uint256 _value) public returns (bool) {
	require(!blacklist[msg.sender]);
	require(balanceOf[msg.sender] >= _value);
	balanceOf[msg.sender] =balanceOf[msg.sender].sub(_value);
	totalSupply = totalSupply.sub(_value);
	emit Burn(msg.sender, _value);
	return true;
}


/**
* @dev Ban address
*
* @param addr ban addr
*/
function addToBlacklist(address addr) public {
	require(msg.sender == owner);
	blacklist[addr] = true;
}
/**
* @dev Enable address
*
* @param addr enable addr
*/
function removeFromBlacklist(address addr) public {
	require(msg.sender == owner);
	blacklist[addr] = false;
}



// transfer ownership of the contract
function transferOwnership(address newOwner) public {
	require(msg.sender == owner);
	owner = newOwner;
    emit OwnershipTransferred(msg.sender,owner);
} 
}
