// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./IERC20.sol";
import "./IERC2612.sol";
import "./IERC3156FlashLender.sol";

interface IWETH is IERC20, IERC2612, IERC3156FlashLender {
  function flashMinted() external view returns(uint256);
  function deposit() external payable;
  function depositTo(address to) external payable;
  function withdraw(uint256 value) external;
  function withdrawTo(address payable to, uint256 value) external;
  function withdrawFrom(address from, address payable to, uint256 value) external;
  function depositToAndCall(address to, bytes calldata data) external payable returns (bool);
  function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
  function transferAndCall(address to, uint value, bytes calldata data) external returns (bool);
}
