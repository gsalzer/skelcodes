// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../utils/Ownable.sol";
import "../utils/ContractKeys.sol";

/**
 * @title  NftTypeRegistry
 * @author NFTfi
 * @dev Registry for NFT Types supported by NFTfi.
 * Each NFT type is associated with the address of an NFT wrapper contract.
 */
contract NftTypeRegistry is Ownable {
    /* ******* */
    /* STORAGE */
    /* ******* */

    mapping(bytes32 => address) private nftTypes;

    /* ****** */
    /* EVENTS */
    /* ****** */

    /**
     * @notice This event is fired whenever the admins register a ntf type.
     *
     * @param nftType - Nft type represented by keccak256('nft type').
     * @param nftWrapper - Address of the wrapper contract.
     */
    event TypeUpdated(bytes32 indexed nftType, address indexed nftWrapper);

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @notice Sets the admin of the contract.
     * Initializes the wrappers contract addresses for the given batch of NFT Types.
     *
     * @param _admin - Initial admin of this contract.
     * @param _nftTypes - The nft types, e.g. "ERC721", or "ERC1155".
     * @param _nftWrappers - The addresses of the wrapper contract that implements INftWrapper behaviour for dealing
     */
    constructor(
        address _admin,
        string[] memory _nftTypes,
        address[] memory _nftWrappers
    ) Ownable(_admin) {
        _setNftTypes(_nftTypes, _nftWrappers);
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /**
     * @notice Set or update the wrapper contract address for the given NFT Type.
     * Set address(0) for a nft type for un-register such type.
     *
     * @param _nftType - The nft type, e.g. "ERC721", or "ERC1155".
     * @param _nftWrapper - The address of the wrapper contract that implements INftWrapper behaviour for dealing with
     * NFTs.
     */
    function setNftType(string memory _nftType, address _nftWrapper) external onlyOwner {
        _setNftType(_nftType, _nftWrapper);
    }

    /**
     * @notice Batch set or update the wrappers contract address for the given batch of NFT Types.
     * Set address(0) for a nft type for un-register such type.
     *
     * @param _nftTypes - The nft types, e.g. "ERC721", or "ERC1155".
     * @param _nftWrappers - The addresses of the wrapper contract that implements INftWrapper behaviour for dealing
     * with NFTs.
     */
    function setNftTypes(string[] memory _nftTypes, address[] memory _nftWrappers) external onlyOwner {
        _setNftTypes(_nftTypes, _nftWrappers);
    }

    /**
     * @notice This function can be called by anyone to get the contract address that implements the given nft type.
     *
     * @param  _nftType - The nft type, e.g. bytes32("ERC721"), or bytes32("ERC1155").
     */
    function getNftTypeWrapper(bytes32 _nftType) external view returns (address) {
        return nftTypes[_nftType];
    }

    /**
     * @notice Set or update the wrapper contract address for the given NFT Type.
     * Set address(0) for a nft type for un-register such type.
     *
     * @param _nftType - The nft type, e.g. "ERC721", or "ERC1155".
     * @param _nftWrapper - The address of the wrapper contract that implements INftWrapper behaviour for dealing with
     * NFTs.
     */
    function _setNftType(string memory _nftType, address _nftWrapper) internal {
        require(bytes(_nftType).length != 0, "nftType is empty");
        bytes32 nftTypeKey = ContractKeys.getIdFromStringKey(_nftType);

        nftTypes[nftTypeKey] = _nftWrapper;

        emit TypeUpdated(nftTypeKey, _nftWrapper);
    }

    /**
     * @notice Batch set or update the wrappers contract address for the given batch of NFT Types.
     * Set address(0) for a nft type for un-register such type.
     *
     * @param _nftTypes - The nft types, e.g. keccak256("ERC721"), or keccak256("ERC1155").
     * @param _nftWrappers - The addresses of the wrapper contract that implements INftWrapper behaviour for dealing
     * with NFTs.
     */
    function _setNftTypes(string[] memory _nftTypes, address[] memory _nftWrappers) internal {
        require(_nftTypes.length == _nftWrappers.length, "setNftTypes function information arity mismatch");

        for (uint256 i = 0; i < _nftWrappers.length; i++) {
            _setNftType(_nftTypes[i], _nftWrappers[i]);
        }
    }
}

