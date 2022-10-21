// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import './interfaces/IAdjudicator.sol';
import './ForceMove.sol';
import './Outcome.sol';
import './AssetHolder.sol';

/**
 * @dev The NitroAdjudicator contract extends ForceMove and hence inherits all ForceMove methods, and also extends and implements the Adjudicator interface, allowing for a finalized outcome to be pushed to an asset holder.
 */
contract NitroAdjudicator is IAdjudicator, ForceMove {
    /**
     * @notice Allows a finalized channel's outcome to be decoded and one or more AssetOutcomes registered in external Asset Holder contracts.
     * @dev Allows a finalized channel's outcome to be decoded and one or more AssetOutcomes registered in external Asset Holder contracts.
     * @param channelId Unique identifier for a state channel
     * @param turnNumRecord A turnNum that (the adjudicator knows and stores) is supported by a signature from each participant.
     * @param finalizesAt The unix timestamp when this channel will finalize
     * @param stateHash The keccak256 of the abi.encode of the State (struct) stored by the adjudicator
     * @param challengerAddress The address of the participant whom registered the challenge, if any.
     * @param outcomeBytes The encoded Outcome of this state channel.
     */
    function pushOutcome(
        bytes32 channelId,
        uint48 turnNumRecord,
        uint48 finalizesAt,
        bytes32 stateHash,
        address challengerAddress,
        bytes memory outcomeBytes
    ) public override {
        // requirements
        _requireChannelFinalized(channelId);

        bytes32 outcomeHash = keccak256(outcomeBytes);

        _requireMatchingStorage(
            ChannelData(turnNumRecord, finalizesAt, stateHash, challengerAddress, outcomeHash),
            channelId
        );

        Outcome.OutcomeItem[] memory outcome = abi.decode(outcomeBytes, (Outcome.OutcomeItem[]));

        for (uint256 i = 0; i < outcome.length; i++) {
            AssetHolder(outcome[i].assetHolderAddress).setAssetOutcomeHash(
                channelId,
                keccak256(outcome[i].assetOutcomeBytes)
            );
        }
    }

    /**
     * @notice Allows a finalized channel's outcome to be decoded and transferAll to be triggered in external Asset Holder contracts.
     * @dev Allows a finalized channel's outcome to be decoded and one or more AssetOutcomes registered in external Asset Holder contracts.
     * @param channelId Unique identifier for a state channel
     * @param turnNumRecord A turnNum that (the adjudicator knows and stores) is supported by a signature from each participant.
     * @param finalizesAt The unix timestamp when this channel will finalize
     * @param stateHash The keccak256 of the abi.encode of the State (struct) stored by the adjudicator
     * @param challengerAddress The address of the participant whom registered the challenge, if any.
     * @param outcomeBytes The encoded Outcome of this state channel.
     */
    function pushOutcomeAndTransferAll(
        bytes32 channelId,
        uint48 turnNumRecord,
        uint48 finalizesAt,
        bytes32 stateHash,
        address challengerAddress,
        bytes memory outcomeBytes
    ) public {
        // requirements
        _requireChannelFinalized(channelId);

        bytes32 outcomeHash = keccak256(outcomeBytes);

        _requireMatchingStorage(
            ChannelData(turnNumRecord, finalizesAt, stateHash, challengerAddress, outcomeHash),
            channelId
        );

        _transferAllFromAllAssetHolders(channelId, outcomeBytes);
    }

    /**
     * @notice Finalizes a channel by providing a finalization proof, allows a finalized channel's outcome to be decoded and transferAll to be triggered in external Asset Holder contracts.
     * @dev Finalizes a channel by providing a finalization proof, allows a finalized channel's outcome to be decoded and transferAll to be triggered in external Asset Holder contracts.
     * @param largestTurnNum The largest turn number of the submitted states; will overwrite the stored value of `turnNumRecord`.
     * @param fixedPart Data describing properties of the state channel that do not change with state updates.
     * @param appPartHash The keccak256 of the abi.encode of `(challengeDuration, appDefinition, appData)`. Applies to all states in the finalization proof.
     * @param outcomeBytes abi.encode of an array of Outcome.OutcomeItem structs.
     * @param numStates The number of states in the finalization proof.
     * @param whoSignedWhat An array denoting which participant has signed which state: `participant[i]` signed the state with index `whoSignedWhat[i]`.
     * @param sigs An array of signatures that support the state with the `largestTurnNum`.
     */
    function concludePushOutcomeAndTransferAll(
        uint48 largestTurnNum,
        FixedPart memory fixedPart,
        bytes32 appPartHash,
        bytes memory outcomeBytes,
        uint8 numStates,
        uint8[] memory whoSignedWhat,
        Signature[] memory sigs
    ) public {
        bytes32 outcomeHash = keccak256(outcomeBytes);
        bytes32 channelId = _conclude(
            largestTurnNum,
            fixedPart,
            appPartHash,
            outcomeHash,
            numStates,
            whoSignedWhat,
            sigs
        );
        _transferAllFromAllAssetHolders(channelId, outcomeBytes);
    }

    /**
     * @notice Triggers transferAll in all external Asset Holder contracts specified in a given outcome for a given channelId.
     * @dev Triggers transferAll in  all external Asset Holder contracts specified in a given outcome for a given channelId.
     * @param channelId Unique identifier for a state channel
     * @param outcomeBytes abi.encode of an array of Outcome.OutcomeItem structs.
     */
    function _transferAllFromAllAssetHolders(bytes32 channelId, bytes memory outcomeBytes)
        internal
    {
        Outcome.OutcomeItem[] memory outcome = abi.decode(outcomeBytes, (Outcome.OutcomeItem[]));

        for (uint256 i = 0; i < outcome.length; i++) {
            Outcome.AssetOutcome memory assetOutcome = abi.decode(
                outcome[i].assetOutcomeBytes,
                (Outcome.AssetOutcome)
            );
            if (assetOutcome.assetOutcomeType == uint8(Outcome.AssetOutcomeType.Allocation)) {
                AssetHolder(outcome[i].assetHolderAddress).transferAllAdjudicatorOnly(
                    channelId,
                    assetOutcome.allocationOrGuaranteeBytes
                );
            } else {
                revert('_transferAllFromAllAssetHolders: AssetOutcomeType is not an allocation');
            }
        }
    }

    /**
    * @notice Check that the submitted pair of states form a valid transition (public wrapper for internal function _requireValidTransition)
    * @dev Check that the submitted pair of states form a valid transition (public wrapper for internal function _requireValidTransition)
    * @param nParticipants Number of participants in the channel.
    transition
    * @param isFinalAB Pair of booleans denoting whether the first and second state (resp.) are final.
    * @param ab Variable parts of each of the pair of states
    * @param turnNumB turnNum of the later state of the pair.
    * @param appDefinition Address of deployed contract containing application-specific validTransition function.
    * @return true if the later state is a validTransition from its predecessor, reverts otherwise.
    */
    function validTransition(
        uint256 nParticipants,
        bool[2] memory isFinalAB, // [a.isFinal, b.isFinal]
        IForceMoveApp.VariablePart[2] memory ab, // [a,b]
        uint48 turnNumB,
        address appDefinition
    ) public pure returns (bool) {
        return _requireValidTransition(nParticipants, isFinalAB, ab, turnNumB, appDefinition);
    }
}

