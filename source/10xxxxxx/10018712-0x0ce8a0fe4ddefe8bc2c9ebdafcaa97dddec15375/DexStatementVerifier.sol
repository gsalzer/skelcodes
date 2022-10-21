/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
pragma solidity ^0.5.2;

import "DexVerifier.sol";
import "IDexStatementVerifier.sol";
import "FactRegistry.sol";
import "Identity.sol";

contract DexStatementVerifier is IDexStatementVerifier, DexVerifier, FactRegistry, Identity {

    // auxPolynomials contains constraintPolynomial and periodic columns.
    constructor(address[] memory auxPolynomials, address oodsContract,
        uint256 numSecurityBits_, uint256 minProofOfWorkBits_) public
        DexVerifier(auxPolynomials, oodsContract, numSecurityBits_, minProofOfWorkBits_) {
        // solium-disable-previous-line no-empty-blocks
    }

    function identify()
        external pure
        returns(string memory)
    {
        return "StarkWare_DexStatementVerifier_2019_1";
    }

    function verifyProofAndRegister(
        uint256[] calldata proofParams,
        uint256[] calldata proof,
        uint256[] calldata publicInput
    )
        external
    {
        verifyProof(proofParams, proof, publicInput);
        registerFact(keccak256(abi.encodePacked(publicInput)));
    }
}

