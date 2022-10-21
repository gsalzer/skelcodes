// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _currentTokenId;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        require(index < _owners[owner].length, "ERC721Enumerable: owner index out of bounds");
        
        return _owners[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        uint256 tokenId = index + 1;
        require(_exists(tokenId), "ERC721Enumerable: global index out of bounds");
        
        return tokenId;
    }

    function ownerIndexByTokenId(uint256 tokenId) public view virtual returns (uint256) {
        require(_exists(tokenId), "ERC721Enumerable: global index out of bounds");
        
        return _tokens[tokenId].ownerIndex;
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        
        return _owners[owner];
    }
}
