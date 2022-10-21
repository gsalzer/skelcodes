pragma solidity ^0.5.0;

import "./Operators.sol";

contract ERC1155URIProvider is Operators {
    string public staticUri;

    function setUri(string calldata _uri) external onlyOwner {
        staticUri = _uri;
    }

    function uri(uint256) external view returns (string memory) {
        return staticUri;
    }
}

