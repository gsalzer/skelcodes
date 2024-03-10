// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sorbetto-base.sol";

contract StrategySorbettoUsdcEthLp is StrategySorbettoBase {
    // Token addresses
    address public popsicle_usdc_eth_lp = 0xd63b340F6e9CCcF0c997c83C8d036fa53B113546;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySorbettoBase(
          usdc,
          weth,
          popsicle_usdc_eth_lp,
          _governance,
          _strategist,
          _controller,
          _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySorbettoUsdcEthLp";
    }
}

