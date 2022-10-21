pragma solidity 0.5.11;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


contract ICards is IERC721 {

    struct Batch {
        uint48 userID;
        uint16 size;
    }

    function batches(uint index) public view returns (uint48 userID, uint16 size);

    function userIDToAddress(uint48 id) public view returns (address);

    function getDetails(
        uint tokenId
    )
        public
        view
        returns (
        uint16 proto,
        uint8 quality
    );

    function setQuality(
        uint tokenId,
        uint8 quality
    ) public;

    function mintCards(
        address to,
        uint16[] memory _protos,
        uint8[] memory _qualities
    )
        public
        returns (uint);

    function mintCard(
        address to,
        uint16 _proto,
        uint8 _quality
    )
        public
        returns (uint);

    function burn(uint tokenId) public;

    function batchSize()
        public
        view
        returns (uint);
}

contract Forge {

    ICards cards;
    uint8 constant diamond = 1;

    constructor(ICards _cards) public {
        cards = _cards;
    }

    function forge(uint[] memory _ids) public {
        require(
            _ids.length == 5,
            "Forge: must forge 5 at a time"
        );

        (uint16 proto, uint8 quality) = cards.getDetails(_ids[0]);
        address owner = cards.ownerOf(_ids[0]);

        require(
            quality > diamond,
            "Forge: cannot forge diamond cards"
        );

        for (uint i = 1; i < 5; i++) {
            (uint16 nextProto, uint8 nextQuality) = cards.getDetails(_ids[i]);

            require(
                proto == nextProto,
                "Forge: different protos"
            );

            require(
                quality == nextQuality,
                "Forge: different qualities"
            );

            require(
                cards.ownerOf(_ids[i]) == owner,
                "Forge: different owners"
            );

            cards.burn(_ids[i]);
        }

        cards.setQuality(_ids[0], quality - 1);
    }

}
