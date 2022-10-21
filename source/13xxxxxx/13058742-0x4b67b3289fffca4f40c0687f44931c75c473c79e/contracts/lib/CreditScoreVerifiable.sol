// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {Address} from "./Address.sol";

import {ISapphireCreditScore} from "../debt/sapphire/ISapphireCreditScore.sol";
import {SapphireTypes} from "../debt/sapphire/SapphireTypes.sol";

/**
 * @dev Provides the ability of verifying users' credit scores
 */
contract CreditScoreVerifiable {

    using Address for address;

    ISapphireCreditScore public creditScoreContract;

    /**
     * @dev Verifies that the proof is passed if the score is required, and
     *      validates it.
     */
    modifier checkScoreProof(
        SapphireTypes.ScoreProof memory _scoreProof,
        bool _isScoreRequired
    ) {
        if (_scoreProof.account != address(0)) {
            require (
                msg.sender == _scoreProof.account,
                "CreditScoreVerifiable: proof does not belong to the caller"
            );
        }

        bool isProofPassed = _scoreProof.merkleProof.length > 0;

        if (_isScoreRequired) {
            require(
                isProofPassed,
                "CreditScoreVerifiable: proof is required but it is not passed"
            );
        }

        if (isProofPassed) {
            creditScoreContract.verifyAndUpdate(_scoreProof);
        }
        _;
    }
}

