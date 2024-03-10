// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * An NFT representing the Subvisual Universe
 */
contract SubvisualUniverseNFT is ERC721, Ownable, EIP712 {
    using Strings for uint16;
    using ECDSA for bytes32;

    //
    // Constants
    //

    // Mint approval EIP712 TypeHash
    bytes32 public constant MINT_TYPEHASH =
        keccak256("Mint(address account,uint256 tokenId)");

    //
    // Structs
    //
    struct Data {
        uint256 id;
        address owner;
        string uri;
    }

    //
    // State
    //

    /// Base URI for all NFTs
    string public baseURI;

    /// Suffix for the URI of all NFTs;
    string public URISuffix;

    uint16 public width;
    uint16 public height;

    //
    // Events
    //

    /// Emitted when the base URI changes
    event BaseURIUpdated(string newBaseURI);

    /// Emitted when the URI suffix changes
    event URISuffixUpdated(string newURISuffix);

    /**
     * @param _name NFT name
     * @param _symbol NFT symbol
     * @param _newBaseURI base URI to use for assets
     * @param _newURISuffix URI suffix to use for assets
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _newBaseURI,
        string memory _newURISuffix,
        uint16 _width,
        uint16 _height,
        address _owner
    ) ERC721(_name, _symbol) EIP712(_name, "1.0.0") {
        _transferOwnership(_owner);

        baseURI = _newBaseURI;
        URISuffix = _newURISuffix;

        width = _width;
        height = _height;

        emit BaseURIUpdated(_newBaseURI);
        emit URISuffixUpdated(_newURISuffix);
    }

    //
    // Public API
    //

    function coordsToId(uint16 x, uint16 y) external pure returns (uint256) {
        return (uint256(x) << 16) + uint256(y);
    }

    function idToCoords(uint256 id) public pure returns (uint16 x, uint16 y) {
        x = uint16(id >> 16);
        y = uint16(id & ((2 << 16) - 1));
    }

    /**
     * Returns info for a token based on his ID
     *
     * @param tokenId the token ID
     * @return token data
     */
    function tokenData(uint256 tokenId) external view returns (Data memory) {
        return _getTokenData(tokenId);
    }

    /**
     * Updates the base URI
     *
     * @notice Only callable by an authorized operator
     *
     * @param _newBaseURI new base URI for the token
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;

        emit BaseURIUpdated(_newBaseURI);
    }

    /**
     * Updates the URI suffix
     *
     * @notice Only callable by an authorized operator
     *
     * @param _newURISuffix new URI suffix for the token
     */
    function setURISuffix(string memory _newURISuffix) public onlyOwner {
        URISuffix = _newURISuffix;

        emit URISuffixUpdated(_newURISuffix);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        (uint16 x, uint16 y) = idToCoords(tokenId);

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        x.toString(),
                        "x",
                        y.toString(),
                        URISuffix
                    )
                )
                : "";
    }

    /**
     * Mints a new NFT
     *
     * @param _tokenId token ID to mint
     * @param _sig EIP712 signature to validate
     */
    function redeem(uint256 _tokenId, bytes calldata _sig) external {
        require(inBoundaries(_tokenId), "not inside the grid");

        require(_verify(_hash(_msgSender(), _tokenId), _sig), "invalid sig");
        _safeMint(_msgSender(), _tokenId);
    }

    function inBoundaries(uint256 _tokenId) public view returns (bool) {
        (uint16 x, uint16 y) = idToCoords(_tokenId);

        return (x < width && y < height);
    }

    function _inBoundaries(uint256 _tokenId) internal view returns (bool) {
        (uint16 x, uint16 y) = idToCoords(_tokenId);

        return (x < width && y < height);
    }

    /**
     * Mints a new NFT on behalf of an account
     *
     * @notice Only callable by an approved operator
     *
     * @param _to Address of the recipient
     * @param _tokenId token ID to mint
     */
    function redeemFor(address _to, uint256 _tokenId) external onlyOwner {
        _safeMint(_to, _tokenId);
    }

    //
    // ERC721
    //
    function _baseURI() internal view returns (string memory) {
        return baseURI;
    }

    //
    // Internal API
    //

    function _getTokenData(uint256 _id) internal view returns (Data memory) {
        if (_exists(_id)) {
            return Data(_id, ownerOf[_id], tokenURI(_id));
        } else {
            return Data(0, address(0), "");
        }
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return ownerOf[_id] != address(0);
    }

    /**
     * Computes the EIP712 Hash of a mint authorization
     *
     * @param _account Account who will mint the NFT
     * @param _tokenId ID of token to mint
     * @return The resulting EIP712 Hash
     */
    function _hash(address _account, uint256 _tokenId)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(abi.encode(MINT_TYPEHASH, _account, _tokenId))
            );
    }

    /**
     * Verifies a mint approval
     *
     * @param _digest The EIP712 hash digest
     * @param _sig The signature to check
     * @return true if the signature matches the hash, and corresponds to a valid minter role
     */
    function _verify(bytes32 _digest, bytes memory _sig)
        internal
        view
        returns (bool)
    {
        return owner() == _digest.recover(_sig);
    }

    function recover(
        address addr,
        uint256 _tokenId,
        bytes calldata _sig
    ) external view returns (address) {
        return ECDSA.recover(_hash(addr, _tokenId), _sig);
    }
}

