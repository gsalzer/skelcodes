// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Address.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is IERC721 {
    using Address for address;

    struct Token {
        address owner;
        address approval;
        uint256 ownerIndex;
    }

    mapping(uint256 => Token) internal _tokens;
    mapping(address => uint256[]) _owners;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 internal _currentTokenId = 0;

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _owners[owner].length;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");

        return _tokens[tokenId].owner;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId > 0 && tokenId <= _currentTokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");

        address owner = _tokens[tokenId].owner;

        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokens[tokenId].approval = to;

        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokens[tokenId].approval;
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        address sender = msg.sender;
        require(operator != sender, "ERC721: approve to caller");

        _operatorApprovals[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `count` tokens and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `count` must positive.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 count) internal virtual {
        uint256[] storage userTokens = _owners[to];
        uint256 tokensCount = userTokens.length;
        uint256 tokenId = _currentTokenId;

        for (uint i = 0; i < count; i++) {
            userTokens.push(++tokenId);
            _tokens[tokenId] = Token(to, address(0), tokensCount++);

            emit Transfer(address(0), to, tokenId);
        }

        _currentTokenId = tokenId;
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        require(to != address(0), "ERC721: transfer to the zero address");

        Token memory token = _tokens[tokenId];
        address sender = msg.sender;
        
        require(token.owner == from, "ERC721: transfer of token that is not own");
        require(from != to, "ERC721: transfer to himself");
        require(
            (sender == token.owner || token.approval == sender || isApprovedForAll(token.owner, sender)),
            "ERC721: transfer caller is not owner nor approved"
        );

        uint256[] storage prevOwnerTokens = _owners[from];
        uint256[] storage newOwnerTokens = _owners[to];
        uint256 lastTokenIndex = prevOwnerTokens.length - 1;

        if(lastTokenIndex >= 1 && token.ownerIndex != lastTokenIndex)
        {
            uint256 lastTokenId = prevOwnerTokens[lastTokenIndex];
            prevOwnerTokens[token.ownerIndex] = lastTokenId;
            _tokens[lastTokenId].ownerIndex = token.ownerIndex;
        }
        
        prevOwnerTokens.pop();
        _tokens[tokenId] = Token(to, address(0), newOwnerTokens.length);
        newOwnerTokens.push(tokenId);

        emit Approval(from, address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}
