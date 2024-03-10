// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IRiddleBrain is IERC20 {
  function mint(address recepient, uint amount) external;
  function burn(address account, uint amount) external;
  function addMinter(address _minter) external;
}

