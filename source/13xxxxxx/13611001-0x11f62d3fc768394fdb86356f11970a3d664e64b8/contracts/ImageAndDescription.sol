//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ImageAndDescription {
    address public parent;

    modifier onlyParent() {
        require(msg.sender == parent, "ImageAndDescription: only parent");
        _;
    }

    constructor(address _parent) {
        parent = _parent;
    }

    function image(uint256 tokenId) external view virtual onlyParent returns (string memory) {}
    function description(uint256 tokenId) external view virtual onlyParent returns (string memory) {}
}
