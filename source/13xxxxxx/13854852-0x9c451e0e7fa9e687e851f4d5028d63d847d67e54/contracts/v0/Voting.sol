// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract Voting {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * `Voter => candidate` mapping
     *
     * Contains each voter's decision. Each decision is a candidate's address
     * for the maintainer of the contract the voter gave their votes for.
     * When the voter casts their votes for `address(0)`, such voter is treated
     * as abstained.
     */
    mapping(address => address) internal _votersDecisions;

    /**
     * A set of voters, i.e. the accounts who left their votes for a particular
     * candidate's address either implicitly (purchasing tokens from the
     * token contract) or explicitly (calling `ToonTokenV0.vote()` method) regardless
     * of their balance. Voters who cast their votes for `address(0)`
     * are being removed from this set.
     */
    EnumerableSet.AddressSet internal _voters;

    /**
     * Emitted when a `voter` announces their decision to cast their votes
     * for `candidate`'s address (incl. `address(0)`).
     */
    event Vote(address voter, address candidate);

    /**
     * Stores `voter`'s decision to cast their votes for the `candidate`'s
     * address. `Candidate` can be `address(0)` meaning that the `voter` decided
     * to abstain.
     */
    function _vote(address voter, address candidate) internal {
        require(voter != address(0), "vote from the zero address");

        if (_votersDecisions[voter] != candidate) {
            _votersDecisions[voter] = candidate;

            // small cleanup to keep the list of voters as small as possible
            if (candidate == address(0)) {
                _voters.remove(voter);
            } else {
                _voters.add(voter);
            }

            emit Vote(voter, candidate);
        }
    }

    // Reserved storage space to allow for layout changes in the future.
    // solhint-disable-next-line ordering
    uint256[48] private __gap;
}

