// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.6.10;

import "./__SafeMath.sol";

/**
 * @dev Suggestions and Voting for token-holders.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract Voting {
    using SafeMath for uint256;

    struct Suggestion {
        uint256 votes;
        bool created;
        address creator;
        string text;
    }

    // This stores how many votes a user has cast on a suggestion
    mapping(uint256 => mapping(address => uint256)) private voted;

    // This map stores the suggestions, and they're retrieved using their ID number
    mapping(uint256 => Suggestion) internal suggestions;

    // This keeps track of the number of suggestions in the system
    uint256 public suggestionCount;

    // If true, a wallet can only vote on a suggestion once
    bool public oneVotePerAccount = true;

    event SuggestionCreated(uint256 suggestionId, string text);
    event Votes(
        address voter,
        uint256 indexed suggestionId,
        uint256 votes,
        uint256 totalVotes,
        string comment
    );

    /**
     * @dev Gets the number of votes a suggestion has received.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getVotes(uint256 suggestionId) public view returns (uint256) {
        return suggestions[suggestionId].votes;
    }

    /**
     * @dev Gets the number of votes for every suggestion in the contract.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getAllVotes() public view returns (uint256[] memory) {
        uint256[] memory votes = new uint256[](suggestionCount);

        for (uint256 i = 0; i < suggestionCount; i++) {
            votes[i] = suggestions[i].votes;
        }

        return votes;
    }

    /**
     * @dev Gets the text of a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getSuggestionText(uint256 suggestionId) public view returns (string memory) {
        return suggestions[suggestionId].text;
    }

    /**
     * @dev Gets whether or not an account has voted for a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function hasVoted(address account, uint256 suggestionId) public view returns (bool) {
        return voted[suggestionId][account] > 0;
    }

    /**
     * @dev Gets the number of votes an account has cast towards a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getAccountVotes(address account, uint256 suggestionId) public view returns (uint256) {
        return voted[suggestionId][account];
    }

    /**
     * @dev Gets the creator of a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getSuggestionCreator(uint256 suggestionId) public view returns (address) {
        return suggestions[suggestionId].creator;
    }

    /**
     * @dev Gets the creator for every suggestion in the contract.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getAllSuggestionCreators() public view returns (address[] memory) {
        address[] memory creators = new address[](suggestionCount);

        for (uint256 i = 0; i < suggestionCount; i++) {
            creators[i] = suggestions[i].creator;
        }

        return creators;
    }

    /**
     * @dev Internal logic for creating a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function _createSuggestion(string memory text) internal {
        // The ID is just based on the suggestion count, so the IDs go 0, 1, 2, etc.
        uint256 suggestionId = suggestionCount++;

        // Starts at 0 votes
        suggestions[suggestionId] = Suggestion(0, true, msg.sender, text);

        emit SuggestionCreated(suggestionId, text);
    }

    /**
     * @dev Internal logic for voting.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function _vote(
        address account,
        uint256 suggestionId,
        uint256 votes,
        string memory comment
    ) internal returns (uint256) {
        if (oneVotePerAccount) {
            require(!hasVoted(account, suggestionId));
            require(votes == 1);
        }
        Suggestion storage sugg = suggestions[suggestionId];
        require(sugg.created);

        voted[suggestionId][account] = voted[suggestionId][account].add(votes);
        sugg.votes = sugg.votes.add(votes);

        emit Votes(account, suggestionId, votes, sugg.votes, comment);

        return sugg.votes;
    }
}

