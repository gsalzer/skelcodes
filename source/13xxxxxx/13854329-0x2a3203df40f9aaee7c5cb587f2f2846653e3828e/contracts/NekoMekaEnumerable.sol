// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./INeko.sol";

/**
 * @dev This is a fork of openzeppelin ERC721Enumerable. It is gas-optimizated for NFT collection
 * with random picked token id when minting, and support sold and claimed count. The updated part includes:
 * - replaced the array `_allToken` with a mapping `_tokensByReversedIndex`,
 * - updated the functions `totalSupply`, `tokenByIndex`, and `_beforeTokenTransfer`.
 * - added functions `_pickRandomId` for picking a non-minted random token id, and some helper functions
 *   `sold`, `claimed`
 */
abstract contract NekoMekaEnumerable is ERC721, INeko, IERC721Enumerable {
    // the number of mintable tokens, including sellable and claimable
    uint16 public immutable mintable;

    // the number of sellable tokens
    uint16 public immutable buyable;

    // the number of sold count, need to be increased by its implementaion contract
    uint16 internal _sold;

    // the number of claimed count, need to be increased by its implementaion contract
    uint16 internal _claimed;

    // Array for all token ids and reversed mint index, used for randomized id pick up and token enumeration
    // Imagine it is defined as an array of [0, 1, 2, 3, ... mintable - 1]
    // Value at the end of mapping is the first minted token id after the first mint.
    // Hardcoded 11000 since we only serve at most 11000 tokens.
    uint16[11000] internal _tokensByReversedIndex;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Fix mintable and buyable number when initialize
    constructor(uint16 mintable_, uint16 buyable_) {
        mintable = mintable_;
        buyable = buyable_;
    }

    function sold() public view returns (uint256) {
        return _sold;
    }

    function claimed() public view returns (uint256) {
        return _claimed;
    }

    /// Return a random non-picked tokenId
    /// @dev See https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle for the details of shuffling algorithm
    function _pickRandomId(uint256 _currentlyMinted) internal returns (uint256 value) {
        // Step 1. Randomly pick a slot within the non-used slots
        uint256 remaining = mintable - _currentlyMinted;
        // Randomly get the slot index for this mint cycle
        uint256 randomlyPickedIndex = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.difficulty,
                    // solhint-disable-next-line not-rely-on-time
                    block.timestamp,
                    remaining
                )
            )
        ) % remaining;
        // If the slot is empty, means we didn't swap it before and assume its content is same as index,
        // Otherwise, use the stored value directly
        if (_tokensByReversedIndex[randomlyPickedIndex] == 0) {
            value = randomlyPickedIndex;
        } else {
            value = _tokensByReversedIndex[randomlyPickedIndex];
        }

        // Step 2. Swap the current slot with the random picked slot
        uint256 currentSlotIndex = remaining - 1;
        // If the current slot is empty, assuming the slot == curent slot index,
        // Otherwise, use the value inside the slot to swap
        if (_tokensByReversedIndex[currentSlotIndex] == 0) {
            _tokensByReversedIndex[randomlyPickedIndex] = uint16(currentSlotIndex);
        } else {
            _tokensByReversedIndex[randomlyPickedIndex] = _tokensByReversedIndex[currentSlotIndex];
        }

        // store the value to the current slot for `tokenByIndex`
        _tokensByReversedIndex[currentSlotIndex] = uint16(value);
    }

    // INeko implementation
    function tokensOfOwner(address _owner) external view override returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0); // Return an empty array
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // IERC721Enumerable Implementation

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(index < ERC721.balanceOf(_owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[_owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _sold + _claimed;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        // solhint-disable-next-line reason-string
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _tokensByReversedIndex[mintable - 1 - index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0) && from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }

        if (to != address(0) && to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
}

