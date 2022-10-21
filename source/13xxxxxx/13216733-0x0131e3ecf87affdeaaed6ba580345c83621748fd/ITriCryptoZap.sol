// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface ITriCryptoZap {
    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

    function add_liquidity(
        uint256[3] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[3] memory _min_amounts) external returns (uint256[3] memory);

    function remove_liquidity(
        uint256 _amount,
        uint256[3] memory _min_amounts,
        address _receiver
    ) external returns (uint256[3] memory);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 _min_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 _min_amount,
        address _receiver
    ) external returns (uint256);

    function pool() external view returns (address);

    function token() external view returns (address);

    function coins(uint256 arg0) external view returns (address);
}

