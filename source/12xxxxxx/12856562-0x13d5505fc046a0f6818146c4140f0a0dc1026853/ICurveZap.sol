// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface ICurveZapSimple {
    function add_liquidity(uint256[3] memory _deposit_amounts, uint256 _min_mint_amount) external;

    function add_liquidity(
        uint256[3] memory _deposit_amounts,
        uint256 _min_mint_amount,
        bool use_underlying
    ) external;

    function add_liquidity(uint256[4] memory _deposit_amounts, uint256 _min_mint_amount) external;

    function add_liquidity(
        address _pool,
        uint256[4] memory _deposit_amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);

    function add_liquidity(
        address _pool,
        uint256[4] memory _deposit_amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        bool _donate_dust
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_one_coin(
        address pool,
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        address _receiver
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        address _receiver
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_withdraw_one_coin(
        uint256 _token_amount,
        int128 i,
        bool use_underlying
    ) external view returns (uint256);

    function calc_withdraw_one_coin(
        address pool,
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);
}

