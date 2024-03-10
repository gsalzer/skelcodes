// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

interface ILiquidityMigrator {
    struct MigrateV2Params {
        address pair; // the Uniswap v2-compatible pair
        address token0;
        address token1;
        uint24 fee;
        uint8 percentageToMigrate; // represented as a numerator over 100
        uint256 liquidityToMigrate;
        uint256 sqrtPriceX96;
        uint256 unipilotTokenId;
        bool refundAsETH;
    }

    struct MigrateV3Params {
        address token0;
        address token1;
        uint24 fee;
        uint8 percentageToMigrate;
        uint256 sqrtPriceX96;
        uint256 uniswapTokenId;
        uint256 unipilotTokenId;
        bool refundAsETH;
    }

    struct UnipilotParams {
        address sender;
        address token0;
        address token1;
        uint24 fee;
        uint256 amount0ToMigrate;
        uint256 amount1ToMigrate;
        uint256 unipilotTokenId;
        uint256 sqrtPriceX96;
    }

    struct RefundLiquidityParams {
        address token0;
        address token1;
        uint256 amount0Unipilot;
        uint256 amount1Unipilot;
        uint256 amount0Recieved;
        uint256 amount1Recieved;
        uint256 amount0ToMigrate;
        uint256 amount1ToMigrate;
        bool refundAsETH;
    }

    event LiquidityMigratedFromV2(
        address pairV2,
        address unipilotVault,
        address owner,
        uint256 unipilotId,
        uint256 amount0,
        uint256 amount1
    );

    event LiquidityMigratedFromV3(
        address unipilotVault,
        address owner,
        uint256 unipilotId,
        uint256 amount0,
        uint256 amount1
    );

    event LiquidityMigratedFromVisor(
        address hypervisor,
        address unipilotVault,
        address owner,
        uint256 unipilotId,
        uint256 amount0,
        uint256 amount1
    );

    event LiquidityMigratedFromLixir(
        address lixirVault,
        address unipilotVault,
        address owner,
        uint256 unipilotId,
        uint256 amount0,
        uint256 amount1
    );

    event LiquidityMigratedFromPopsicle(
        address popsicleVault,
        address unipilotVault,
        address owner,
        uint256 unipilotId,
        uint256 amount0,
        uint256 amount1
    );
}

