// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IChainlinkOracle
} from "../../interfaces/chainlink/IChainlinkOracle.sol";
import {ETH} from "../../constants/CTokens.sol";
import {IOracleAggregator} from "../../interfaces/gelato/IOracleAggregator.sol";
import {IGelato} from "../../diamond/interfaces/IGelato.sol";

function _getGelatoGasPrice(address _gasPriceOracle) view returns (uint256) {
    return uint256(IChainlinkOracle(_gasPriceOracle).latestAnswer());
}

function _getGelatoFee(
    uint256 _gasOverhead,
    uint256 _gasStart,
    address _payToken,
    address _gelato
) view returns (uint256 gelatoFee) {
    gelatoFee =
        (_gasStart - gasleft() + _gasOverhead) *
        _getCappedGasPrice(IGelato(_gelato).getGasPriceOracle());

    if (_payToken == ETH) return gelatoFee;

    // returns purely the ethereum tx fee
    (gelatoFee, ) = IOracleAggregator(IGelato(_gelato).getOracleAggregator())
        .getExpectedReturnAmount(gelatoFee, ETH, _payToken);
}

function _getCappedGasPrice(address _gasPriceOracle) view returns (uint256) {
    uint256 oracleGasPrice = _getGelatoGasPrice(_gasPriceOracle);

    // Use tx.gasprice capped by 1.3x Chainlink Oracle
    return
        tx.gasprice <= ((oracleGasPrice * 130) / 100)
            ? tx.gasprice
            : ((oracleGasPrice * 130) / 100);
}

