// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import '../IModule.sol';

/// @notice Signaling - used for gathering feedback and sentiment.
/// * Continous voting, no deadlines and always open.
/// * No quorum required.
/// * 0.001% of TVL needed to propose.
// Audit-1: ok
contract FeatureFarmSignaling is IModule {
  /// @notice Called if a proposal gets created.
  /// Requirements:
  /// - proposerBalance needs to be at least 0.001% of TVL.
  function onCreateProposal (
    bytes32 /*communityId*/,
    uint256 /*totalMemberCount*/,
    uint256 totalValueLocked,
    address /*proposer*/,
    uint256 proposerBalance,
    uint256 /*startDate*/,
    bytes calldata /*internalActions*/,
    bytes calldata /*externalActions*/
  ) external pure override
  {
    uint256 minProposerBalance = totalValueLocked / 100_000;
    require(
      proposerBalance >= minProposerBalance,
      'Not enough balance'
    );
  }

  /// @notice Signaling Proposals are forever open.
  /// The resulting voting signal is `totalVotingSignal / totalVoteCount` if `totalVoteCount > 0`,
  /// else `0`.
  function onProcessProposal (
    bytes32 /*proposalId*/,
    bytes32 /*communityId*/,
    uint256 /*totalMemberCount*/,
    uint256 totalVoteCount,
    uint256 /*totalVotingShares*/,
    uint256 totalVotingSignal,
    uint256 /*totalValueLocked*/,
    uint256 /*secondsPassed*/
  ) external pure override returns (VotingStatus, uint256, uint256) {
    return (VotingStatus.OPEN, uint256(-1), totalVoteCount == 0 ? 0 : totalVotingSignal / totalVoteCount);
  }
}

