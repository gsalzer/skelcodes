// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import '../../utils/SafeMath.sol';
import './ERC20Base.sol';

abstract contract ERC20Extended is ERC20Base {
  using SafeMath for uint;

  function increaseAllowance (address spender, uint amount) virtual public returns (bool) {
    _approve(msg.sender, spender, ERC20BaseStorage.layout().allowances[msg.sender][spender].add(amount));
    return true;
  }

  function decreaseAllowance (address spender, uint amount) virtual public returns (bool) {
    _approve(msg.sender, spender, ERC20BaseStorage.layout().allowances[msg.sender][spender].sub(amount));
    return true;
  }
}

