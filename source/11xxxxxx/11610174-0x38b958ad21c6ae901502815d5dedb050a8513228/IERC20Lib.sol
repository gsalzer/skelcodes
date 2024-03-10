// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20Lib {
  function init(address owner_, string memory name_, string memory symbol_, uint256 totalSupply_) external;
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
