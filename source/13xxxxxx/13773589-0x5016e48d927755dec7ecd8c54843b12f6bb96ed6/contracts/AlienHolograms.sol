// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AlienHolograms is ERC1155Supply, Ownable { // rename
    using Strings for uint256;

    event SetUri(string uri);
    event Mint(address receiver);

    string public baseURI;

    constructor(string memory _uri) ERC1155("") {
        baseURI = _uri;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, _id.toString()));
    }

    function setUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
        emit SetUri(_uri);
    }
    
    function mint(address _to, uint _id, uint _count) external onlyOwner {
        _mint(_to, _id, _count, "");
        emit Mint(_to);
    }

}

