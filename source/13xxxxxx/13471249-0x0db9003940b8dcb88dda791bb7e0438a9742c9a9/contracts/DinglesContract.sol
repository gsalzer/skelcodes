/**
 *
 * Copyright Notice: User must include the following signature.
 *
 * Smart Contract Developer: www.QambarRaza.com
 *
 * ..#######.....###....##.....##.########.....###....########.
 * .##.....##...##.##...###...###.##.....##...##.##...##.....##
 * .##.....##..##...##..####.####.##.....##..##...##..##.....##
 * .##.....##.##.....##.##.###.##.########..##.....##.########.
 * .##..##.##.#########.##.....##.##.....##.#########.##...##..
 * .##....##..##.....##.##.....##.##.....##.##.....##.##....##.
 * ..#####.##.##.....##.##.....##.########..##.....##.##.....##
 * .########.....###....########....###...
 * .##.....##...##.##........##....##.##..
 * .##.....##..##...##......##....##...##.
 * .########..##.....##....##....##.....##
 * .##...##...#########...##.....#########
 * .##....##..##.....##..##......##.....##
 * .##.....##.##.....##.########.##.....##
 */

// SPDX-License-Identifier: Apache 2.0


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "./library/ERC2981ContractWideRoyalties.sol";

/**
 * @title DinglesContract contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract DinglesContract is 
    ERC721Enumerable, 
    ERC2981ContractWideRoyalties, 
    Ownable {
    using SafeMath for uint256;

    string public DNGL_PROVENANCE = "";

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public constant dinglePrice = 80000000000000000; //0.08 ETH

    uint256 public constant maxDinglePurchase = 22;

    uint256 public MAX_DINGLES;

    bool public saleIsActive = false;

    uint256 public REVEAL_TIMESTAMP;

    string private baseURI;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxNftSupply,
        uint256 saleStart,
        uint256 royaltyPercentage
    ) ERC721(name, symbol) {
        MAX_DINGLES = maxNftSupply;
        REVEAL_TIMESTAMP = saleStart;
        
        setRoyalies(owner(), royaltyPercentage * 100);
    }

    function setRoyalies(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Set some Dingle aside 
     */
    function reserveDingle(
        uint256 quantity, 
        address reservationWalletAddress
    ) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < quantity; i++) {
            _safeMint(reservationWalletAddress, supply + i);
        }
    }

    /**
     * Sets the reveal timestamp
     */
    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    }

    /*
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        DNGL_PROVENANCE = provenanceHash;
    }
    
    function isMinted(uint256 tokenId) external view returns (bool) {
        require(tokenId < MAX_DINGLES , "tokenId outside collection bounds");

        return _exists(tokenId);
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * Mints Dingle
     */
    function mintDingle(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Dingle");
        require(
            numberOfTokens <= maxDinglePurchase,
            "Can only mint 22 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_DINGLES,
            "Purchase would exceed max supply of Dingle"
        );
        require(
            dinglePrice.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_DINGLES) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (
            startingIndexBlock == 0 &&
            (totalSupply() == MAX_DINGLES || block.timestamp >= REVEAL_TIMESTAMP)
        ) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % MAX_DINGLES;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % MAX_DINGLES;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }
}

