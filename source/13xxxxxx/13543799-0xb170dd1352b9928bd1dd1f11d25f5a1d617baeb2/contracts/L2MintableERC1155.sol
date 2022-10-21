// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./lib/AddressSet.sol";
import "./lib/Claimable.sol";
import "./lib/Ownable.sol";

import "./thirdparty/erc165/ERC165.sol";
import "./thirdparty/erc165/IERC165.sol";

import "./thirdparty/erc1155/Context.sol";
import "./thirdparty/erc1155/ERC1155.sol";
import "./thirdparty/erc1155/IERC1155.sol";
import "./thirdparty/erc1155/IERC1155MetadataURI.sol";
import "./thirdparty/erc1155/IERC1155Receiver.sol";
import "./thirdparty/erc1155/SafeMath.sol";

import "./MintAuthorization.sol";

contract L2MintableERC1155 is ERC1155, Claimable {
    event MintFromL2(address owner, uint256 id, uint256 amount, address minter);

    string public name;

    // Authorization for which addresses can mint tokens and add collections is
    // delegated to another contract.
    // TODO: (Loopring feedback) Make this field immutable when contract is upgradable
    MintAuthorization private authorization;

    // The IPFS hash for each collection (these hashes represent a directory within
    // IPFS that contain one JSON file per edition in the collection).
    mapping(uint64 => string) private _ipfsHashes;

    modifier onlyFromLayer2() {
        require(_msgSender() == authorization.layer2(), "UNAUTHORIZED");
        _;
    }

    modifier onlyMinter(address addr) {
        require(
            authorization.isActiveMinter(addr) ||
                authorization.isRetiredMinter(addr),
            "NOT_MINTER"
        );
        _;
    }

    modifier onlyFromUpdater() {
        require(authorization.isUpdater(msg.sender), "NOT_FROM_UPDATER");
        _;
    }

    // Prevent initialization of the implementation deployment.
    // (L2MintableERC1155Factory should be used to create usable instances.)
    constructor() {
        owner = 0x000000000000000000000000000000000000dEaD;
    }

    // An init method is used instead of a constructor to allow use of the proxy
    // factory pattern. The init method can only be called once and should be
    // called within the factory.
    function init(
        address _owner,
        address _authorization,
        string memory _name
    ) public {
        require(owner == address(0), "ALREADY_INITIALIZED");
        require(_owner != address(0), "OWNER_REQUIRED");

        _registerInterface(_INTERFACE_ID_ERC1155);
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
        _registerInterface(_INTERFACE_ID_ERC165);

        owner = _owner;
        name = _name;
        authorization = MintAuthorization(_authorization);
    }

    // This function is called when an NFT minted on L2 is withdrawn from Loopring.
    // That means the NFTs were burned on L2 and now need to be minted on L1.
    // This function can only be called by the Loopring exchange.
    function mintFromL2(
        address to,
        uint256 tokenId,
        uint256 amount,
        address minter,
        bytes calldata data
    ) external onlyFromLayer2 onlyMinter(minter) {
        _mint(to, tokenId, amount, data);
        emit MintFromL2(to, tokenId, amount, minter);
    }

    // Allow only the owner to mint directly on L1
    // TODO: (Loopring feedback) Can be removed once contract is upgrabable
    function mint(
        address tokenId,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external onlyOwner {
        _mint(tokenId, id, amount, data);
    }

    // All address that are currently authorized to mint NFTs on L2.
    function minters() public view returns (address[] memory) {
        return authorization.activeMinters();
    }

    // Delegate authorization to a different contract (can be called by an owner to
    // "eject" from the GameStop ecosystem).
    // TODO: (Loopring feedback) Should be removed once contract is upgrabable
    function setAuthorization(address _authorization) external onlyOwner {
        authorization = MintAuthorization(_authorization);
    }

    function uri(uint256 id) external view override returns (string memory) {
        // The layout of an ID is: 64 bit creator ID, 64 bits of flags, 64 bit
        // collection ID then 64 bit edition ID:
        uint64 collectionId = uint64(
            (id &
                0x00000000000000000000000000000000FFFFFFFFFFFFFFFF0000000000000000) >>
                64
        );
        uint64 editionId = uint64(
            id &
                0x000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF
        );

        string memory ipfsHash = _ipfsHashes[collectionId];
        require(bytes(ipfsHash).length != 0, "NO_IPFS_BASE");

        return
            _appendStrings(
                "ipfs://",
                ipfsHash,
                "/",
                _uintToString(editionId),
                ".json"
            );
    }

    function setIpfsHash(uint64 collectionId, string memory ipfsHash)
        external
        onlyFromUpdater
    {
        string memory existingIpfsHash = _ipfsHashes[collectionId];
        require(bytes(existingIpfsHash).length == 0, "IPFS_ALREADY_SET");
        _ipfsHashes[collectionId] = ipfsHash;
    }

    function getIpfsHash(uint64 collectionId)
        external
        view
        returns (string memory)
    {
        return _ipfsHashes[collectionId];
    }

    function _appendStrings(
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e
    ) private pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }

    // TODO: (Loopring feedback) Is there a library that implements this?
    function _uintToString(uint256 input)
        private
        pure
        returns (string memory _uintAsString)
    {
        if (input == 0) {
            return "0";
        }

        uint256 i = input;
        uint256 length = 0;
        while (i != 0) {
            length++;
            i /= 10;
        }

        bytes memory result = new bytes(length);
        i = length;
        while (input != 0) {
            i--;
            uint8 character = (48 + uint8(input - (input / 10) * 10));
            result[i] = bytes1(character);
            input /= 10;
        }
        return string(result);
    }
}

