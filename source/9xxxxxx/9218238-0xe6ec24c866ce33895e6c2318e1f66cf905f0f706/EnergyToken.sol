pragma solidity ^0.5.0;



/**------------------------------------

ENERGY Token   

Energy Token is a new ERC20 token that is human-neutral, trustless, and scarce.  The contract is non-owned, meaning there is no monarch and no initial supply. 

The acquire energy tokens, simply send Proof of Work pure-mined 0xBTC tokens to the contract and that will mint new Energy tokens.  


------------------------------------*/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


contract EnergyToken {

    using SafeMath for uint;

    address constant public masterToken = 0xB6eD7644C69416d67B522e20bC294A9a9B405B31;

    string public name     = "Energy";
    string public symbol   = "EGY";
    uint8  public decimals = 8;
    uint private _totalSupply;

    event  Approval(address indexed src, address indexed ext, uint amt);
    event  Transfer(address indexed src, address indexed dst, uint amt);
    event  Deposit(address indexed dst, uint amt);
    event  Withdrawal(address indexed src, uint amt);

    mapping (address => uint)                       public  balances;
    mapping (address => mapping (address => uint))  public  allowance;  

  

    constructor() public {

    }

    /**
    * Do not allow ETH to enter
    */
     function() external payable
     {
         revert();
     }


    /**
     * @dev Deposit original tokens, receive proxy tokens 1:1
     * This method requires token approval.
     *
     * @param amount of tokens to deposit
     */
    function mutateTokens(address from, uint amount) public returns (bool)
    {

        require( amount >= 0 );

        require( ERC20Interface( masterToken ).transferFrom( from, address(this), amount) );

        balances[from] = balances[from].add(amount);
        _totalSupply = _totalSupply.add(amount);

        emit Transfer(address(this), from, amount);

        return true;
    }


 


   //standard ERC20 method
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

   //standard ERC20 method
     function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     //standard ERC20 method
    function getAllowance(address owner, address spender) public view returns (uint)
    {
      return allowance[owner][spender];
    }

   //standard ERC20 method
  function approve(address spender,   uint tokens) public returns (bool success) {
      allowance[msg.sender][spender] = tokens;
      emit Approval(msg.sender, spender, tokens);
      return true;
  }


  //standard ERC20 method
   function transfer(address to,  uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


   //standard ERC20 method
   function transferFrom( address from, address to,  uint tokens) public returns (bool success) {
       balances[from] = balances[from].sub(tokens);
       allowance[from][to] = allowance[from][to].sub(tokens);
       balances[to] = balances[to].add(tokens);
       emit Transfer( from, to, tokens);
       return true;
   }

  
 
 
   


   
 
 
 


       /*
         Receive approval from ApproveAndCall() to mutate tokens.

         This method allows 0xBTC to be mutated into this token using a single method call.
       */
     function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public returns (bool success) {

        require(token == masterToken);

        require(mutateTokens(from, tokens));

        return true;

     }


 

     function bytesEqual(bytes memory b1,bytes memory b2) pure internal returns (bool)
        {
          if(b1.length != b2.length) return false;

          for (uint i=0; i<b1.length; i++) {
            if(b1[i] != b2[i]) return false;
          }

          return true;
        }




}
