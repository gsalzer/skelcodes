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

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC2981Royalties.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
