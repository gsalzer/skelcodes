pragma solidity 0.4.24;

import './ERC20Token.sol';
import './SafeMath.sol';

contract StandardToken is ERC20Token {

  using SafeMath for uint256;

  // Global variable to store total number of tokens passed from FRSPToken.sol
  uint256 _totalSupply;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address tokenOwner) public view returns (uint256){
        return balances[tokenOwner];
  }



  function transfer(address to, uint256 tokens) public returns (bool){
      require(to != address(0));
      require(tokens > 0 && tokens <= balances[msg.sender]);

      balances[msg.sender] = balances[msg.sender].sub(tokens);
      balances[to] = balances[to].add(tokens);
      emit Transfer(msg.sender, to, tokens);
      return true;
  }

  // Transfer tokens from one address to another
  function transferFrom(address from, address to, uint256 tokens) public returns (bool success){
      require(to != address(0));
      require(tokens > 0 && tokens <= balances[from]);
      require(tokens <= allowed[from][msg.sender]);

      balances[from] = balances[from].sub(tokens);
      balances[to] = balances[to].add(tokens);
      allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
      emit Transfer(from, to, tokens);

      return true;
  }

  // Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
  function approve(address spender, uint256 tokens) public returns (bool success){
      allowed[msg.sender][spender] = tokens;
      emit Approval(msg.sender, spender, tokens);
      return true;
  }

  // Function to check the amount of tokens that an owner allowed to a spender.
  function allowance(address tokenOwner, address spender) public view returns (uint256 remaining){
      return allowed[tokenOwner][spender];
  }

  // Increase the amount of tokens that an owner allowed to a spender.
  // approve should be called when allowed[spender] == 0.
  // To increment allowed value is better to use this function to avoid 2 calls (and wait until the first transaction is mined)
  function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
    allowed[msg.sender][spender] = (allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  // Decrease the amount of tokens that an owner allowed to a spender.
  // approve should be called when allowed[spender] == 0.
  // To decrement allowed value is better to use this function to avoid 2 calls (and wait until the first transaction is mined)
  function decreaseApproval(address spender, uint256 subtractedValue ) public returns (bool){
    uint256 oldValue = allowed[msg.sender][spender];
    if (subtractedValue >= oldValue) {
      allowed[msg.sender][spender] = 0;
    } else {
      allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

}

