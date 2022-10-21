// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface ICurveDepositor {
  function A() external view returns (uint256);
  function get_virtual_price() external view returns(uint256);
  function calc_token_amount(uint256[3] calldata amounts, bool deposit) external view returns(uint256);
  function calc_token_amount(uint256[4] calldata amounts, bool deposit) external view returns(uint256);
  function calc_token_amount(uint256[5] calldata amounts, bool deposit) external view returns(uint256);
  function add_liquidity(uint256[3] calldata amounts, uint256 min) external;
  function add_liquidity(uint256[4] calldata amounts, uint256 min) external;
  function add_liquidity(uint256[5] calldata amounts, uint256 min) external;
  function remove_liquidity(uint256 amount, uint256[2] calldata amounts) external;
  function remove_liquidity(uint256 amount, uint256[3] calldata amounts) external;
  function remove_liquidity(uint256 amount, uint256[4] calldata amounts) external;
  function remove_liquidity(uint256 amount, uint256[5] calldata amounts) external;
  function remove_liquidity_one_coin(uint256 amount, int128 i, uint256 min) external;
  function calc_withdraw_one_coin(uint256 amount, int128 i) external view returns(uint256);
}

