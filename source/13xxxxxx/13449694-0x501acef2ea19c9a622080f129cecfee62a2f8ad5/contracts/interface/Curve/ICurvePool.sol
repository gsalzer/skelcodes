// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ICurvePool {
    /**
     * @notice Returns the coin address of the given coin index.
     * @return coin The coin address.
     */
    function coins(uint256 arg0) external view returns (address coin);

    /**
     * @notice Adds liquidity to pool.
     * @param amounts The liquidity amount for each token in the pool.
     * @param minMintAmount The minumum pool lp token mint threshold.
     */
    // solhint-disable-next-line func-name-mixedcase
    function add_liquidity(uint256[] memory amounts, uint256 minMintAmount) external;

    /**
     * @notice Calculates the witdraw amount for given `amount` and `coin`.
     * The given coin index must be valid for the pool.
     * @param tokenAmount The balance of the user in the pool.
     * @param i The coin index.
     * @return amount The withdraw amount.
     */
    // solhint-disable-next-line func-name-mixedcase
    function calc_withdraw_one_coin(uint256 tokenAmount, int128 i) external view returns (uint256 amount);
}

