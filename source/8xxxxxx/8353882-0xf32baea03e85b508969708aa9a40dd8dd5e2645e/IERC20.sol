pragma solidity ^0.5.8;

/**
 * @title ERC20 interface without bool returns
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external;

  function transferFrom(address from, address to, uint256 value) external;

  function decimals() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);
}

