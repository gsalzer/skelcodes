// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//------------------------------------------------------------------------------
//    _______                   __   __        ______ __          __
//   |     __|-----.-----.-----|  |_|__|----. |      |  |--.---.-|__|-----.
//   |    |  |  -__|     |  -__|   _|  |  __| |   ---|     |  _  |  |     |
//   |_______|_____|__|__|_____|____|__|____| |______|__|__|___._|__|__|__|
//
//------------------------------------------------------------------------------
// Genetic Chain: ERC721SeqEnumerableB
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ERC721SequentialB.sol";

/**
 * @dev This is a no storage implementation of the optional extension {ERC721}
 * defined in the EIP that adds enumerability of all the token ids in the
 * contract as well as their owners. These functions are all O(n) and mainly
 * for convenience and should not be called from a contract on the chain.
 */
abstract contract ERC721SeqEnumerableB is ERC721SequentialB, IERC721Enumerable {

    address constant zero = address(0);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC721SequentialB) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view virtual override returns (uint256 tokenId) {
        uint256 length = _owners.length;

        unchecked {
            for (; tokenId < length; ++tokenId) {
                if (_owners[tokenId] == owner) {
                    if (index-- == 0) {
                        break;
                    }
                }
            }
        }

        require(tokenId < length, "ERC721Enumerable: owner index out of bounds");
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256 supply) {
        unchecked {
            uint256 length = _owners.length;
            for (uint256 tokenId = 0; tokenId < length; ++tokenId) {
                if (_owners[tokenId] != zero) {
                    ++supply;
                }
            }
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(
        uint256 index
    ) public view virtual override returns (uint256 tokenId) {
        uint256 length = _owners.length;

        unchecked {
            for (; tokenId < length; ++tokenId) {
                if (_owners[tokenId] != zero) {
                    if (index-- == 0) {
                        break;
                    }
                }
            }
        }

        require(tokenId < length, "ERC721Enumerable: global index out of bounds");
    }

    /**
     * @dev Get all tokens owned by owner.
     */
    function ownerTokens(
        address owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = ERC721SequentialB.balanceOf(owner);
        require(tokenCount != 0, "ERC721Enumerable: owner owns no tokens");

        uint256 length = _owners.length;
        uint256[] memory tokenIds = new uint256[](tokenCount);
        unchecked {
            uint256 i = 0;
            for (uint256 tokenId = 0; tokenId < length; ++tokenId) {
                if (_owners[tokenId] == owner) {
                    tokenIds[i++] = tokenId;
                }
            }
        }

        return tokenIds;
    }

}

