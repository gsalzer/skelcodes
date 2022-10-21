pragma solidity ^0.5.11;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20A {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value,
    uint date
  );
}
