pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./StandardToken.sol";
import "./Pausable.sol";

/**
 * @title SHIN token
 * @dev StandardToken modified with pausable transfers.
 **/
contract SHINToken is StandardToken, Pausable {
  string public constant name = "ShareIN Token";
  string public constant symbol = "SHIN";
  uint256 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**decimals;

  event Issue(uint amount);
  event Redeem(uint amount);

  /**
   * @dev Create and issue tokens to msg.sender.
   */
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  } 

  /**
   * @dev fallback function to send ether to owner
   ** /
  function () external payable whenNotPaused {
    require(msg.value > (2300 * 10**9));
    address payable oaddr = address(uint160(owner));
    oaddr.transfer(msg.value.sub(2300 * 10**9);
  } */

  /**
   * @dev transfer eth to owner
   **/
  function withdraw(uint256 _amt, uint256 _gas) public onlyOwner
    returns (bool) {
    require(_amt > _gas);
    address payable oaddr = address(uint160(owner));
    oaddr.transfer(_amt.sub(_gas));
  }

  /**
   * @dev Transfer tokens when not paused
   **/
  function transfer(address _to, uint256 _value) public whenNotPaused
    returns (bool) {
    return super.transfer(_to, _value);
  }
  
  /**
   * @dev transferFrom function to tansfer tokens when token is not paused
   **/
  function transferFrom(address _from, address _to, uint256 _value)
    public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
  
  /**
   * @dev approve spender when not paused
   **/
  function approve(address _spender, uint256 _value) public whenNotPaused
    returns (bool) {
    return super.approve(_spender, _value);
  }
  
  /**
   * @dev increaseApproval of spender when not paused
   **/
  function increaseApproval(address _spender, uint _addedValue)
    public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }
  
  /**
   * @dev decreaseApproval of spender when not paused
   **/
  function decreaseApproval(address _spender, uint _subtractedValue)
    public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
  
  /**
   * @dev Increase total supply, deposit to owner
   */
  function issue(uint _amount) public onlyOwner {
    require(totalSupply_ + _amount > totalSupply_);
    require(balances[owner] + _amount > balances[owner]);

    balances[owner] += _amount;
    totalSupply_ += _amount;
    emit Issue(_amount);
  }

  /**
   * @dev Decrease total supply, withdraw from owner
   */
  function redeem(uint _amount) public onlyOwner {
    require(totalSupply_ >= _amount);
    require(balances[owner] >= _amount);

    totalSupply_ -= _amount;
    balances[owner] -= _amount;
    emit Redeem(_amount);
  }
}

