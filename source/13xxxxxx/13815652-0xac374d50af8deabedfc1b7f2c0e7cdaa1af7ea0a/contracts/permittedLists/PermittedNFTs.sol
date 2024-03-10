// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IPermittedNFTs.sol";
import "../interfaces/INftTypeRegistry.sol";
import "../interfaces/INftfiHub.sol";

import "../utils/Ownable.sol";
import "../utils/ContractKeys.sol";

/**
 * @title  PermittedNFTs
 * @author NFTfi
 * @dev Registry for NFT contracts supported by NFTfi.
 * Each NFT is associated with an NFT Type.
 */
contract PermittedNFTs is Ownable, IPermittedNFTs {
    /* ******* */
    /* STORAGE */
    /* ******* */

    INftfiHub public hub;

    /**
     * @notice A mapping from an NFT contract's address to the Token type of that contract. A zero Token Type indicates
     * non-permitted.
     */
    mapping(address => bytes32) private nftPermits;

    /* ****** */
    /* EVENTS */
    /* ****** */

    /**
     * @notice This event is fired whenever the admin sets a NFT's permit.
     *
     * @param nftContract - Address of the NFT contract.
     * @param nftType - NTF type e.g. bytes32("CRYPTO_KITTIES")
     */
    event NFTPermit(address indexed nftContract, bytes32 indexed nftType);

    /* ********* */
    /* MODIFIERS */
    /* ********* */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwnerOrAirdropFactory(string memory _nftType) {
        if (
            ContractKeys.getIdFromStringKey(_nftType) ==
            ContractKeys.getIdFromStringKey(ContractKeys.AIRDROP_WRAPPER_STRING)
        ) {
            require(hub.getContract(ContractKeys.AIRDROP_FACTORY) == _msgSender(), "caller is not AirdropFactory");
        } else {
            require(owner() == _msgSender(), "caller is not owner");
        }
        _;
    }

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @dev Sets `nftTypeRegistry`
     * Initialize `nftPermits` with a batch of permitted NFTs
     *
     * @param _admin - Initial admin of this contract.
     * @param _nftfiHub - Address of the NftfiHub contract
     * @param _nftContracts - The addresses of the NFT contracts.
     * @param _nftTypes - The NFT Types. e.g. "CRYPTO_KITTIES"
     * - "" means "disable this permit"
     * - != "" means "enable permit with the given NFT Type"
     */
    constructor(
        address _admin,
        address _nftfiHub,
        address[] memory _nftContracts,
        string[] memory _nftTypes
    ) Ownable(_admin) {
        hub = INftfiHub(_nftfiHub);
        _setNFTPermits(_nftContracts, _nftTypes);
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /**
     * @notice This function can be called by admins to change the permitted list status of an NFT contract. This
     * includes both adding an NFT contract to the permitted list and removing it.
     * `_nftContract` can not be zero address.
     *
     * @param _nftContract - The address of the NFT contract.
     * @param _nftType - The NFT Type. e.g. "CRYPTO_KITTIES"
     * - "" means "disable this permit"
     * - != "" means "enable permit with the given NFT Type"
     */
    function setNFTPermit(address _nftContract, string memory _nftType)
        external
        override
        onlyOwnerOrAirdropFactory(_nftType)
    {
        _setNFTPermit(_nftContract, _nftType);
    }

    /**
     * @notice This function can be called by admins to change the permitted list status of a batch NFT contracts. This
     * includes both adding an NFT contract to the permitted list and removing it.
     * `_nftContract` can not be zero address.
     *
     * @param _nftContracts - The addresses of the NFT contracts.
     * @param _nftTypes - The NFT Types. e.g. "CRYPTO_KITTIES"
     * - "" means "disable this permit"
     * - != "" means "enable permit with the given NFT Type"
     */
    function setNFTPermits(address[] memory _nftContracts, string[] memory _nftTypes) external onlyOwner {
        _setNFTPermits(_nftContracts, _nftTypes);
    }

    /**
     * @notice This function can be called by anyone to lookup the Nft Type associated with the contract.
     * @param  _nftContract - The address of the NFT contract.
     * @notice Returns the NFT Type:
     * - bytes32("") means "not permitted"
     * - != bytes32("") means "permitted with the given NFT Type"
     */
    function getNFTPermit(address _nftContract) external view override returns (bytes32) {
        return nftPermits[_nftContract];
    }

    /**
     * @notice This function can be called by anyone to lookup the address of the NftWrapper associated to the
     * `_nftContract` type.
     * @param _nftContract - The address of the NFT contract.
     */
    function getNFTWrapper(address _nftContract) external view override returns (address) {
        bytes32 nftType = nftPermits[_nftContract];
        return _getWrapper(nftType);
    }

    /**
     * @notice This function changes the permitted list status of an NFT contract. This includes both adding an NFT
     * contract to the permitted list and removing it.
     * @param _nftContract - The address of the NFT contract.
     * @param _nftType - The NFT Type. e.g. bytes32("CRYPTO_KITTIES")
     * - bytes32("") means "disable this permit"
     * - != bytes32("") means "enable permit with the given NFT Type"
     */
    function _setNFTPermit(address _nftContract, string memory _nftType) internal {
        require(_nftContract != address(0), "nftContract is zero address");
        bytes32 nftTypeKey = ContractKeys.getIdFromStringKey(_nftType);

        if (nftTypeKey != 0) {
            require(_getWrapper(nftTypeKey) != address(0), "NFT type not registered");
        }

        require(
            nftPermits[_nftContract] != ContractKeys.getIdFromStringKey(ContractKeys.AIRDROP_WRAPPER_STRING),
            "AirdropWrapper can't be modified"
        );
        nftPermits[_nftContract] = nftTypeKey;
        emit NFTPermit(_nftContract, nftTypeKey);
    }

    /**
     * @notice This function changes the permitted list status of a batch NFT contracts. This includes both adding an
     * NFT contract to the permitted list and removing it.
     * @param _nftContracts - The addresses of the NFT contracts.
     * @param _nftTypes - The NFT Types. e.g. "CRYPTO_KITTIES"
     * - "" means "disable this permit"
     * - != "" means "enable permit with the given NFT Type"
     */
    function _setNFTPermits(address[] memory _nftContracts, string[] memory _nftTypes) internal {
        require(_nftContracts.length == _nftTypes.length, "setNFTPermits function information arity mismatch");

        for (uint256 i = 0; i < _nftContracts.length; i++) {
            _setNFTPermit(_nftContracts[i], _nftTypes[i]);
        }
    }

    /**
     * @notice Returns the wrapper for the nft type
     * @param _nftTypeKey - The key of the nft type
     * @return the address of the wrapper
     */
    function _getWrapper(bytes32 _nftTypeKey) internal view returns (address) {
        INftTypeRegistry nftTypeRegistry = INftTypeRegistry(hub.getContract(ContractKeys.NFT_TYPE_REGISTRY));
        return nftTypeRegistry.getNftTypeWrapper(_nftTypeKey);
    }
}

