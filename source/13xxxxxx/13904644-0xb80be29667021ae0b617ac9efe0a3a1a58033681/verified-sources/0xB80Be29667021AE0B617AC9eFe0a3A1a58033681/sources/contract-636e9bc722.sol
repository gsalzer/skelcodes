// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts@4.4.1/governance/Governor.sol";
import "@openzeppelin/contracts@4.4.1/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts@4.4.1/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts@4.4.1/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts@4.4.1/governance/extensions/GovernorVotesQuorumFraction.sol";

/// @custom:security-contact security@candletoken.com
contract CandleGovernor is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction {
    constructor(ERC20Votes _token)
        Governor("CandleGovernor")
        GovernorSettings(2000 /* 2000 block */, 13091 /* 2 days */, 200000000e18)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
    {}

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotes)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }
}

