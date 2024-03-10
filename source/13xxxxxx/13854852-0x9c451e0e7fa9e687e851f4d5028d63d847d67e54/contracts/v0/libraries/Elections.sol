// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ElectionsPrincipal.sol";

library Elections {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * Finds:
     * - the winning candidate (and the number of votes cast for it),
     * - the number of votes cast for the runner up candidate,
     * - and the total number of votes cast for any candidate but `address(0)`
     *   (such votes are treated as abstained votes)
     * by transforming the set of `voters` (and reading each voter's decision
     * and the number of its votes via `principal`'s interface)
     * into the array of candidates with the sum of votes cast for each candidate,
     * then iterating through this array to find the TOP-2 candidates on the fly.
     *
     * Technical considerations: our experiments show that handling ≈2500 voters
     * with ≈10 unique candidates consumes almost 30M of gas - this is treated
     * as the best-case scenario, and that's why the internal memory arrays
     * are defined with the size of `2500` elements each.
     */
    function findTop2(
        EnumerableSet.AddressSet storage voters,
        ElectionsPrincipal principal
    )
        public
        view
        returns (
            address winningCandidate,
            uint256 winningCandidateVotes,
            uint256 runnerUpCandidateVotes,
            uint256 totalVotes
        )
    {
        (
            address[2500] memory candidatesList,
            uint256[2500] memory candidatesVotes,
            uint256 candidatesCount,
            uint256 totalVotes_
        ) = _convertVotersList(voters, principal);

        require(candidatesCount > 0, "no candidates");

        totalVotes = totalVotes_;

        // iterate thru the list of candidatesVotes making TOP-2 on the fly
        for (uint256 j = 0; j < candidatesCount; j++) {
            uint256 votes = candidatesVotes[j];

            if (votes > winningCandidateVotes) {
                // the winner found within this loop shifts the
                // winner found during previous loops down to the runner up
                runnerUpCandidateVotes = winningCandidateVotes;

                winningCandidate = candidatesList[j];
                winningCandidateVotes = votes;
            } else if (votes > runnerUpCandidateVotes) {
                runnerUpCandidateVotes = votes;
            }
        }
    }

    /**
     * Sums the votes of the `selectedVoters` (reading each voter's decision
     * and the number of its votes via `principal` interface) who cast their
     * votes for the `expectedCandidate`.
     *
     * @param expectedCandidate the candidate whom the votes to be sum where cast for
     * @param selectedVoters the ordered list of voters whose votes cast for the expected candidate should be summed
     * @param principal the interface to read each voter's decision and balance
     */
    function sumVotesFor(
        address expectedCandidate,
        address[] memory selectedVoters,
        ElectionsPrincipal principal
    ) public view returns (uint256 votes) {
        address prevVoter;
        for (uint256 j = 0; j < selectedVoters.length; j++) {
            address voter = selectedVoters[j];
            address candidate = principal.candidateOf(voter);
            if (
                candidate == expectedCandidate &&
                // make sure this list is ordered
                prevVoter < voter
            ) {
                votes += principal.votesOf(voter);
                prevVoter = voter;
            }
        }
    }

    /**
     * Sums the votes of the `selectedVoters` (reading each voter's decision
     * and the number of its votes via `principal` interface) who cast their
     * votes for anyone but `excludedCandidate` and `address(0)`.
     *
     * @param excludedCandidate the candidate whom the votes to not be sum where cast for
     * @param selectedVoters the ordered list of voters whose votes cast for anyone but `excludedCandidate` and `address(0)` should be summed
     * @param principal the interface to read voters' decisions and balances
     */
    function sumVotesExceptZeroAnd(
        address excludedCandidate,
        address[] memory selectedVoters,
        ElectionsPrincipal principal
    ) public view returns (uint256 votes) {
        address prevVoter;
        for (uint256 i = 0; i < selectedVoters.length; i++) {
            address voter = selectedVoters[i];
            address candidate = principal.candidateOf(voter);
            if (
                // exclude unwanted addresses
                candidate != excludedCandidate &&
                candidate != address(0) &&
                // make sure this list is ordered
                prevVoter < voter
            ) {
                votes += principal.votesOf(voter);
                prevVoter = voter;
            }
        }
    }

    /**
     * Determines the consensus. Consensus is reached when the number of `votes`
     * is more than a half of `totalVotes`, otherwise it is broken.
     */
    function calcConsensus(uint256 votes, uint256 totalVotes)
        public
        pure
        returns (bool)
    {
        return votes > (totalVotes / 2);
    }

    /**
     * Internal function to transform the set of `voters` into the array of
     * candidates.
     *
     * This function iterates through the set of `voters`, reading each
     * voter's decision and the number of votes via `principal` interface.
     *  A voter's decision is represented by the address of the candidate he/she
     * decided to cast its votes for;
     * a voter's number of votes is represented by the number of tokens at
     * its balance.
     *
     * Each found candidate is added to the `candidatesList` (only once),
     * and the number of votes given for him are added to the `candidatesVotes`
     * at the same index this candidate has been added to `candidatesList`.
     * Additionally, this function keeps track of the number of found candidates
     * via `candidatesCount` and the total number of votes cast for all
     * candidates (except `address(0)`) via `totalVotes`.
     */
    function _convertVotersList(
        EnumerableSet.AddressSet storage voters,
        ElectionsPrincipal principal
    )
        private
        view
        returns (
            address[2500] memory candidatesList,
            uint256[2500] memory candidatesVotes,
            uint256 candidatesCount,
            uint256 totalVotes
        )
    {
        // each found candidate is added to the candidatesList, and the number
        // of votes given for it are added at the respective index
        // in the candidatesVotes
        for (uint256 i = 0; i < voters.length(); i++) {
            address voter = voters.at(i);
            uint256 voterBalance = principal.votesOf(voter);
            address candidate = principal.candidateOf(voter);

            // a voter must have positive balance, and its candidate
            // must not be address(0)
            if (voterBalance > 0 && candidate != address(0)) {
                totalVotes += voterBalance;

                // this candidate may have been already added to the list,
                // we must look it up
                (bool found, uint256 foundIndex) = _findIndex(
                    candidate,
                    candidatesList,
                    candidatesCount
                );

                if (found) {
                    candidatesVotes[foundIndex] += voterBalance;
                } else {
                    candidatesList[candidatesCount] = candidate;
                    candidatesVotes[candidatesCount] = voterBalance;
                    candidatesCount++;
                }
            }
        }
    }

    /**
     * Internal function that returns the index of the element inside `array`
     * which is equal to `predicate`. If such element is not found, `found` is
     * set to `false`.
     */
    function _findIndex(
        address predicate,
        address[2500] memory array,
        uint256 length
    ) private pure returns (bool found, uint256 index) {
        for (uint256 j = 0; j < length; j++) {
            if (predicate == array[j]) {
                return (true, j);
            }
        }
    }
}

