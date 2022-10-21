// contracts/BlackSphereCore.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";
import {Colors} from "./Colors.sol";

/**
 * The base contract for BlackSphere tokens.
 */
contract BlackSphereCore is ERC721URIStorage, Ownable {

    constructor() ERC721("Black Sphere", "BLCKSPHR") {}

    // counters
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _generation;
    
    // blcksphrs data
    mapping(uint256 => BlackSphere) private _blcksphrs;

    // This struct is created to store some onchain information for the tokens.
    struct BlackSphere {
        string name; // Piece name
        bytes16 dna; // Dna, for future usage
        uint64 birthTime; // Allways setted by this contract
        Colors.Color bg; // 32b
        uint8 generation; // Allways setted by this contract
        uint8 mana; // Mana bonus, for future usage
        uint8 power; // Power bonus, for future usage
        uint8 boost; // Boost bonus, for future usage
    }

    // This struct is created for all the information needed to mint a blcksphr
    struct BlackSphereMintData {
        string tokenURI;
        string name;
        bytes16 dna;
        Colors.Color bg;
        uint8 mana;
        uint8 power;
        uint8 boost;
    }

    /**
     * @dev Shows/Gets the BlackSphere.
     *
     * @return The BlackSphere struct.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getBlackSphere(uint256 tokenId)
        public
        view
        virtual
        returns (BlackSphere memory)
    {
        require(
            _exists(tokenId),
            "BlackSphere: BlackSphere query for nonexistent token"
        );
        return _blcksphrs[tokenId];
    }

    /**
     * Sets the Token URI. This is for exceptional cases and maintainance where,
     * for example, IPFS dies, or there is a mistake in the data.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(uint256 tokenId, string memory newTokenURI)
        public
        onlyOwner
    {
        require(
            _exists(tokenId),
            "BlackSphere: setTokenURI for nonexistent token"
        );
        _setTokenURI(tokenId, newTokenURI);
    }

    /**
     * Ends a generation of tokens, and starts a new one.
     * All new tokens will be generated with the new generation number.
     * This is a way to ensure no new previous generation tokens will be minted.
     */
    function endGeneration() public onlyOwner {
        _generation.increment();
    }

    /**
     * Shows the current generation.
     * If a new token is minted, will be of this generation.
     */
    function getGeneration() public view returns(uint256) {
        return _generation.current();
    }

    /**
     * @dev Public wrapper for minting.
     *
     * @return The token id.
     */
    function mint(
        address firstOwner,
        BlackSphereMintData memory blackSphereMintData
    ) public onlyOwner returns (uint256) {
        return
            _realMint(firstOwner, blackSphereMintData);
    }

    /**
     * @dev Mints multiple BLCKSPHR tokens.
     */
    function multipleMint(address firstOwner, BlackSphereMintData[] memory blackSphereMintDataArray)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < blackSphereMintDataArray.length; i++) {
            _realMint(firstOwner, blackSphereMintDataArray[i]);
        }
    }

    /**
     * @dev Mints multiple BLCKSPHR tokens, and ends the generation.
     */
    function mintGeneration(address firstOwner, BlackSphereMintData[] memory blackSphereMintDataArray)
        public
        onlyOwner
    {
        multipleMint(firstOwner, blackSphereMintDataArray);
        endGeneration();
    }

    /**
     * @dev Mints a new BLCKSPHR token.
     *
     * @return The token id.
     */
    function _realMint(
        address firstOwner,
        BlackSphereMintData memory blackSphereMintData
    ) internal onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        uint256 generation = _generation.current();
        _mint(firstOwner, newTokenId);
        _setTokenURI(newTokenId, blackSphereMintData.tokenURI);
        _setBlackSphere(
            newTokenId,
            BlackSphere(
                blackSphereMintData.name,
                blackSphereMintData.dna,
                uint64(block.timestamp),
                blackSphereMintData.bg,
                uint8(generation),
                uint8(blackSphereMintData.mana),
                uint8(blackSphereMintData.power),
                uint8(blackSphereMintData.boost)
            )
        );
        return newTokenId;
    }

    /**
     * @dev Sets `_blcksphrs` as the BlackSphere of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setBlackSphere(uint256 tokenId, BlackSphere memory _blcksphr)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "BlackSphere: BlackSphere set of nonexistent token"
        );
        _blcksphrs[tokenId] = _blcksphr;
    }
}

