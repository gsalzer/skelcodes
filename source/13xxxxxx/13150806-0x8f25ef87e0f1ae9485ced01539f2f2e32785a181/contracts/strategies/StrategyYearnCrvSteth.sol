// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategyYearnAffiliate.sol";

contract StrategyYearnCrvSteth is StrategyYearnAffiliate {
    // Token addresses
    address public constant crv_steth_lp = 0x06325440D014e39736583c165C2963BA99fAf14E;
    address public constant yearn_registry = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        StrategyYearnAffiliate(
            crv_steth_lp,
            yearn_registry,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}
}

