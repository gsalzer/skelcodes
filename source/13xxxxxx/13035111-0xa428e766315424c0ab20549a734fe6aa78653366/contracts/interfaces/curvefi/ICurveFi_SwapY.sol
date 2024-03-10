// SPDX-License-Identifier: None
pragma solidity 0.6.12;

/**
 * @dev Interface for Curve.Fi swap contract for Y-pool.
 * @dev See original implementation in official repository:
 * https://github.com/curvefi/curve-contract/blob/master/contracts/pools/y/StableSwapY.vy
 */
interface ICurveFi_SwapY {
    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 _amount, uint256[4] calldata min_amounts) external;
    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;
    function calc_token_amount(uint256[4] calldata amounts, bool deposit) external view returns(uint256);

    function balances(int128 i) external view returns(uint256);
    function coins(int128 i) external view returns (address);

    function get_virtual_price() external view returns(uint256);
}
