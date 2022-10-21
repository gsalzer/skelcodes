// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./ERC721Upgradeable.sol";

abstract contract ERC721GenDefaultApproval is ERC721Upgradeable {
    mapping(address => bool) private defaultApprovals;

    event DefaultApproval(address indexed operator, bool hasApproval);

    function __ERC721GenDefaultApproval_init_unchained(address operator) internal initializer {
        bool hasApproval = true;
        defaultApprovals[operator] = hasApproval;
        emit DefaultApproval(operator, hasApproval);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal virtual override view returns (bool) {
        return defaultApprovals[spender] || super._isApprovedOrOwner(spender, tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return defaultApprovals[operator] || super.isApprovedForAll(owner, operator);
    }
    uint256[50] private __gap;
}

