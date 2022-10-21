// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
  function maxFlashLoan(address token) external view returns (uint256);
  function flashFee(address token, uint256 amount) external view returns (uint256);
  function flashLoan(
      IERC3156FlashBorrower receiver,
      address token,
      uint256 amount,
      bytes calldata data
  ) external returns (bool);
}

