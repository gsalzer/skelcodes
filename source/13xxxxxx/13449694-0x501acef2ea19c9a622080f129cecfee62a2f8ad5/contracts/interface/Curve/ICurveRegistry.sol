// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ICurveRegistry {
    /**
     * @notice Returns `Curve Pool` address for given `Curve LP Token`.
     * @param token LP token address.
     * @return pool `Curve Pool` address.
     */
    // solhint-disable-next-line func-name-mixedcase
    function get_pool_from_lp_token(address token) external view returns (address pool);
    
    /**
     * @notice Returns `LP Token` for given `Curve Pool`.
     * @param pool Curve Pool address.
     * @return token `LP Token` address.
     */
    // solhint-disable-next-line func-name-mixedcase
    function get_lp_token(address pool) external view returns (address token);
   
    /**
     * @notice Returns the number of coins for given `Curve Pool`.
     * @param pool Curve Pool address.
     * @return n_coins The coin count in the pool.
     */
    // solhint-disable-next-line func-name-mixedcase, var-name-mixedcase
    function get_n_coins(address pool) external view returns (uint256 n_coins);

    /**
     * @notice Returns total pool count in the `Curve Protocol`.
     * @return poolCount The total `Curve Pool` count.
     */
    // solhint-disable-next-line func-name-mixedcase
    function pool_count() external view returns (uint256 poolCount);

    /**
     * @notice Returns `Curve Pool` address for given pool index.
     * @param poolIndex The index of the pool.
     * @return pool  The address of the pool.
     */
    // solhint-disable-next-line func-name-mixedcase
    function pool_list(uint256 poolIndex) external view returns (address pool);

    /**
     * @notice Returns the total coin count in the `Curve Protocol`.
     * @return coinCount The total count of coins.
     */
    // solhint-disable-next-line func-name-mixedcase
    function coin_count() external view returns (uint256 coinCount);

    /**
     * @notice Returns the coin address for given coin index.
     * @return coin The address of the coin.
     */
    // solhint-disable-next-line func-name-mixedcase
    function get_coin(uint256 coinIndex) external view returns (address coin);

    /**
     * @notice Returns the name of pool.
     * @param pool The address of the pool.
     * @return name The name of the pool.
     *
    */
    // solhint-disable-next-line func-name-mixedcase
    function get_pool_name(address pool) external view returns (string memory name);

    /**
     * @notice Returns the underlying coins of the pool.
     * @param pool the address of the pool.
     * @return underlyingCoins The underlying coins.
    */
    // solhint-disable-next-line func-name-mixedcase
    function get_underlying_coins(address pool) external view returns (address[8] memory underlyingCoins);

    /**
     * @notice Returns the underlying decimals of the pool.
     * @param pool the address of the pool.
     * @return underlyingDecimals The underlying coins.
    */
    // solhint-disable-next-line func-name-mixedcase
    function get_underlying_decimals(address pool) external view returns (uint256[8] memory underlyingDecimals);

    /**
     * @notice Returns the coins of the pool.
     * @param pool the address of the pool.
     * @return coins The pool coins.
    */
    // solhint-disable-next-line func-name-mixedcase
    function get_coins(address pool) external view returns (address[8] memory coins);

}

