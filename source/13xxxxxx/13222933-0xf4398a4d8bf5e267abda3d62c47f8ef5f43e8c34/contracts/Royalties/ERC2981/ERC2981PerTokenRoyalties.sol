// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import './IERC2981Royalties.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981PerTokenRoyalties is ERC165, IERC2981Royalties {
    struct Royalty {
        address recipient;
        uint256 value;
    }

    mapping(uint256 => Royalty) private _royalties;

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC2981Royalties).interfaceId;
    }

    /// @dev Sets token royalties
    /// @param id the token id fir which we register the royalties
    function _removeRoyalty(uint256 id) internal {
        delete _royalties[id];
    }

    /// @dev Sets token royalties
    /// @param id the token id fir which we register the royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(
        uint256 id,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');

        _royalties[id] = Royalty(recipient, value);
    }

    /// @dev Gets token royalties
    /// @param id the token id for which we check the royalties
    function _getTokenRoyalty(uint256 id)
        internal
        view
        returns (address, uint256)
    {
        Royalty memory royalty = _royalties[id];
        return (royalty.recipient, royalty.value);
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 tokenId, uint256 value)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        Royalty memory royalty = _royalties[tokenId];
        return (royalty.recipient, (value * royalty.value) / 10000);
    }
}

