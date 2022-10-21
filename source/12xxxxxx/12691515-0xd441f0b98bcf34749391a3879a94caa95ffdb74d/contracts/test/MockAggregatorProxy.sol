// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@chainlink/contracts/src/v0.7/dev/AggregatorProxy.sol";

contract MockAggregatorProxy is AggregatorProxy {
    constructor(
        address aggregatorAddress
    ) AggregatorProxy(aggregatorAddress) {} // solhint-disable-line
}

