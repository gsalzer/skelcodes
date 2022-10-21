//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IGUniFactory {
    event PoolCreated(
        address indexed uniPool,
        address indexed manager,
        address indexed pool
    );

    function createPool(
        address tokenA,
        address tokenB,
        uint24 uniFee,
        uint16 managerFee,
        int24 lowerTick,
        int24 upperTick,
        string memory tokenIdentifier
    ) external returns (address pool);
}

