// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./StrategyIdle.sol";

/**
 * Adds the mainnet addresses to the StrategyIdle
 * BY = Best-Yield
 */
contract StrategyIdleUSDC_BY is StrategyIdle {
    address public constant __comp = address(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    address public constant __idle = address(0x875773784Af8135eA0ef43b5a374AaD105c5D39e);
    address public constant __weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address public constant __idleReservoir = address(0x031f71B5369c251a6544c41CE059e6b3d61e42C6);

    address public constant __idleYieldToken = address(0x5274891bEC421B39D23760c04A6755eCB444797C);
    address public constant __referral = address(0x652c1c23780d1A015938dD58b4a65a5F9eFBA653);
    address public constant __uniswapRouterV2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor(address _vault)
        public
        StrategyIdle(_vault, __comp, __idle, __weth, __idleReservoir, __idleYieldToken, __referral, __uniswapRouterV2)
    {}

    function name() external override pure returns (string memory) {
        return "StrategyIdleUSDC_BY";
    }
}

