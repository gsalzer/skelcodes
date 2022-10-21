// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./UniqueKeyGenerator.sol";

abstract contract VotingSystem is UniqueKeyGenerator {
    // fields to help with voting
    mapping(bytes32 => bool) internal isCandidate;
    
    // candidates
    mapping(bytes32 => uint256) internal votes;
    struct VotingCycle {
        uint256 id;
        address[] candidates;
        address leader;
        uint256 leaderVotes;
        bool tied;
    }
    VotingCycle internal currentVotingCycle;

    // voters
    mapping(bytes32 => bool) internal voted;

    // proposers
    mapping(bytes32 => bool) internal addedProposal;

    VotingStatus internal currentStatus;
    enum VotingStatus { INACTIVE, ACTIVE }
    enum StartVotingOutcome { STARTED, UNCONTESTED, NO_CANDIDATES }
    enum StopVotingOutcome { STOPPED, NO_VOTES, TIE }
    address internal latestWinner;
    uint256 internal numVotesHeld;

    event VotingActive(uint256 votingSessionNumber);
    event VotingInactive(address winner, uint256 numVotes);
    event VotingExtended();
    event VotingPostponed(string reason);
    event VoteUncontested(address winner);
    event VoteCounted(address indexed voter, address indexed vote);
    event CandidateAdded(address indexed candidate, address indexed addedBy);

    // constants
    string constant duplicateCandidateMsg = "The proposed candidate has already been added.";
    string constant alreadyAddedCandidateMsg = "The sender's address has already proposed a candidate";
    string constant alreadyVotedMsg = "The sender's address has already voted this cycle";
    string constant noMatchingCandidateMsg = "No matching candidate exists this voting cycle";
    string constant votingInactiveMsg = "Votes cannot be cast while voting state is INACTIVE (0)";
    string constant votingActiveMsg = "Candidates cannot be proposed while voting state is ACTIVE (2)";

    // START -> voting is active
    function startVoting() internal returns (StartVotingOutcome outcome, address winner) {
        assert(currentStatus == VotingStatus.INACTIVE);
        if (currentVotingCycle.candidates.length != 0 && currentVotingCycle.candidates.length > 1) {
            currentStatus = VotingStatus.ACTIVE;
            numVotesHeld++;
            emit VotingActive(numVotesHeld);
            return (StartVotingOutcome.STARTED, address(0));
        }
        if (currentVotingCycle.candidates.length == 1) {
            numVotesHeld++;
            latestWinner = currentVotingCycle.candidates[0];
            emit VoteUncontested(latestWinner);
            resetVotingState();
            return (StartVotingOutcome.UNCONTESTED, latestWinner);
        }
        emit VotingPostponed("No candidates");
        return (StartVotingOutcome.NO_CANDIDATES, address(0));
    }

    // INACTIVE -> voting is over, winner is determined, and options are reset
    function stopVoting() internal returns (StopVotingOutcome outcome, address winner) {
        assert(currentStatus == VotingStatus.ACTIVE);
        if (currentVotingCycle.leader == address(0)) {
            currentStatus = VotingStatus.INACTIVE;
            emit VotingPostponed("No votes cast");
            return (StopVotingOutcome.NO_VOTES, address(0));
        }
        if (currentVotingCycle.tied) {
            emit VotingExtended();
            return (StopVotingOutcome.TIE, address(0));
        }
        currentStatus = VotingStatus.INACTIVE;
        emit VotingInactive(currentVotingCycle.leader, currentVotingCycle.leaderVotes);
        latestWinner = currentVotingCycle.leader;
        resetVotingState();
        return (StopVotingOutcome.STOPPED, latestWinner);
    }

    function addCandidate(address candidate, address proposer) internal {
        require(currentStatus == VotingStatus.INACTIVE, votingActiveMsg);
        bytes32 proposerKey = generateKey(proposer);
        bytes32 candidateKey = generateKey(candidate);
        require(!addedProposal[proposerKey], alreadyAddedCandidateMsg);
        require(!isCandidate[candidateKey], duplicateCandidateMsg);
        isCandidate[candidateKey] = true;
        addedProposal[proposerKey] = true;
        currentVotingCycle.candidates.push(candidate);
        emit CandidateAdded(candidate, proposer);
    }

    function voteForCandidate(address vote, address voter) internal {
        require(currentStatus == VotingStatus.ACTIVE, votingInactiveMsg);
        bytes32 voteKey = generateKey(vote);
        bytes32 voterKey = generateKey(voter);
        require(!voted[voterKey], alreadyVotedMsg);
        require(isCandidate[voteKey], noMatchingCandidateMsg);
        votes[voteKey]++;
        voted[voterKey] = true;
        adjustLeader(vote, votes[voteKey]);
        emit VoteCounted(voter, vote);
    }

    function adjustLeader(address vote, uint256 numVotes) private {
        if (numVotes == currentVotingCycle.leaderVotes) {
            currentVotingCycle.tied = true;
        } else if (numVotes > currentVotingCycle.leaderVotes) {
            currentVotingCycle.leaderVotes = numVotes;
            currentVotingCycle.leader = vote;
            currentVotingCycle.tied = false;
        }
    }

    function resetVotingState() private {
        VotingCycle memory vc;
        vc.id = currentVotingCycle.id + 1;
        currentVotingCycle = vc;
        addSalt();
        postVoteCleanUp();
    }

    function postVoteCleanUp() internal virtual;

    // getters to check voting data

    function getVotingStatus() public view returns (VotingStatus) {
        return currentStatus;
    }

    function isVotingActive() public view returns (bool) {
        return currentStatus == VotingStatus.ACTIVE;
    }

    function getIsCandidate(address a) public view returns (bool) {
        return isCandidate[generateKey(a)];
    }

    function getNumberOfVotes(address a) public view returns (uint256) {
        return votes[generateKey(a)];
    }

    function getCurrentLeader() public view returns (address) {
        return currentVotingCycle.leader;
    }

    function getCurrentLeaderVoteCount() public view returns (uint256) {
        return currentVotingCycle.leaderVotes;
    }

    function getCurrentVotingCycleId() public view returns (uint256) {
        return currentVotingCycle.id;
    }

    function isCurrentlyTied() public view returns (bool) {
        return currentVotingCycle.tied;
    }

    function hasAlreadyVoted(address a) public view returns (bool) {
        return voted[generateKey(a)];
    }

    function hasAlreadyAddedCandidate(address a) public view returns (bool) {
        return addedProposal[generateKey(a)];
    }

    function mostRecentWinner() public view returns (address) {
        return latestWinner;
    }

    function totalVoteSessionsHeld() public view returns (uint256) {
        return numVotesHeld;
    }
}
