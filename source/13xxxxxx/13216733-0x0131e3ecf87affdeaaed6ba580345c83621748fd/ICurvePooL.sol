// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface ICurvePooL {
    function get_virtual_price() external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function A() external view returns (uint256);

    function lp_token() external view returns (address);

    function calc_token_amount(uint256[3] memory amounts, bool deposit) external view returns (uint256);

    function calc_token_amount(uint256[4] memory amounts, bool is_deposit) external view returns (uint256);

    function calc_token_amount(uint256[2] memory amounts, bool is_deposit) external view returns (uint256);

    function coins(uint256 arg0) external view returns (address);

    function coins(int128 arg0) external returns (address out);
}

