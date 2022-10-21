// SPDX-License-Identifier: --🥺--

pragma solidity =0.7.0;

contract ProvableTest is usingProvable {
    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 7;
    
    event LogNewProvableQuery(string description);
    event GenerationStatus(string description);

    constructor() {
        provable_setProof(proofType_Ledger);
        provable_setCustomGasPrice(10000000000);
    }
 
    function test() external {
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 200000;

        provable_newRandomDSQuery(QUERY_EXECUTION_DELAY, NUM_RANDOM_BYTES_REQUESTED, GAS_FOR_CALLBACK);
        emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
    }

    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof ) public override {
        require(msg.sender == provable_cbAddress(), 'can only be called by Oracle');

        if (provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof ) != 0 ) {
            emit GenerationStatus("return 0");
        } else {
            emit GenerationStatus("return 1");
        }
    }
}

import './provableAPI_0.6.sol';
