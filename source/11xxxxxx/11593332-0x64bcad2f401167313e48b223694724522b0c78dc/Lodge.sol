// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { ILodge } from "./ILodge.sol";
import { LodgeBase } from "./LodgeBase.sol";
import { LodgeToken } from "./LodgeToken.sol";

contract Lodge is ILodge, LodgeBase {
    event TokenCreated(address user, uint256 id, uint256 supply);

    uint256 public constant MASK_FROST = 0;
    uint256 public constant GOGGLES_FROST = 1;
    uint256 public constant JACK_FROST = 2;

    mapping(uint256 => uint256) public override items; // total supply of each token
    mapping(uint256 => uint256) public boosts;

    constructor(address _addressRegistry) 
        public 
        LodgeBase(_addressRegistry, "https://frostprotocol.com/items/{id}.json")
    {
        _initializeSnowboards();
    }

    // Base Altitude NFTs
    function _initializeSnowboards() internal virtual {
        // mainnet amounts
        mint(lgeAddress(), MASK_FROST, 5, 600);
        mint(lgeAddress(), GOGGLES_FROST, 10, 300);
        mint(treasuryAddress(), JACK_FROST, 20, 150);
    }

    // Governed function to set URI in case of domain/api changes
    function setURI(string memory _newuri)
        public
        override(LodgeToken, ILodge)
    {
        _setURI(_newuri);       
    }

    function boost(uint256 _id) 
        external 
        override
        view 
        returns (uint256)
    {
        return boosts[_id];
    }

    // Governed function to create a new NFT
    // Cannot mint any NFT more than once
    function mint(
        address _account,
        uint256 _id,
        uint256 _amount,
        uint256 _boost
    )
        public
        override
        HasPatrol("ADMIN")
    {
        require(items[_id] == 0, "Cannot mint NFT more than once");

        _mint(_account, _id, _amount, "");
        items[_id] = _amount;
        boosts[_id] = _boost;

        emit TokenCreated(_msgSender(), _id, _amount);
    }

    function setBoost(uint256 _id, uint256 _boost)
        external
        HasPatrol("ADMIN")
    {
        boosts[_id] = _boost;
    }
}
