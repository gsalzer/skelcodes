// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

interface IOffchainAggregator {
    function owedPayment(address _transmitter) external view returns (uint256);

    function withdrawPayment(address _transmitter) external;

    function transferPayeeship(address _transmitter, address _proposed) external;

    function acceptPayeeship(address _transmitter) external;
}

