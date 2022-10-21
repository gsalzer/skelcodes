// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice the stablecoin pool contract
 */
interface IStableSwap3Pool {
    function coins(uint256 coin) external view returns (address);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}

