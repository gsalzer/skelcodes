// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Celebrate is ERC721Tradable {
    string private uribaseToken_;
    
    constructor(address _proxyRegistryAddress, string memory _baseuri)
        ERC721Tradable("CelebrateNFT", "CLB", _proxyRegistryAddress)
    {
        uribaseToken_ = _baseuri;
    }

    function baseTokenURI() override public view returns (string memory) {
        return uribaseToken_;
    }

    function contractURI() public view returns (string memory) {
        return uribaseToken_;
    }
    
    function updateUri(string memory _uri)public onlyOwner{
        uribaseToken_ = _uri;
    }
}

