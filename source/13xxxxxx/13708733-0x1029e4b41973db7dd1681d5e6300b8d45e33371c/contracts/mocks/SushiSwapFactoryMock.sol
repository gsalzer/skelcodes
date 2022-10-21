// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../uniswapv2/SSFV2Factory.sol";

contract SushiSwapFactoryMock is SSFV2Factory {
    constructor(address _feeToSetter) public SSFV2Factory(_feeToSetter) {}
}
