// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;


import "./IBridge.sol";


interface IDAO {
    struct EthAction {
        uint value;
        uint160 target;
        string signature;
        bytes data;
    }

    function updateBridge(
        address _bridge
    ) external;

    function execute(
        bytes memory payload,
        bytes[] memory signatures
    ) external returns(bytes[] memory responses);

    event UpdateBridge(address indexed bridge);
    event UpdateConfiguration(IBridge.TONAddress configuration);
}

