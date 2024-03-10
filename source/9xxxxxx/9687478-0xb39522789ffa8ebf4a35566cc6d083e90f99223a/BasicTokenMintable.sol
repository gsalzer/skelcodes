pragma solidity ^0.4.24;


import "./BasicToken.sol";
import "./SafeMath.sol";


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicTokenMintable is BasicToken {
  using SafeMath for uint256;

  function mint(address account, uint256 amount) internal {
    require(account != address(0));
    totalSupply_ = totalSupply_.add(amount);
    balances[account] = balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }
}

