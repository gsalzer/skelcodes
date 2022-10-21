// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Operators.sol";

/**
 * @dev this contract used just for override some
 * OpneZeppelin tokenURI() behavior
 * so we need redeclare _tokenURIs becouse in OpenZeppelin
 * ERC721 it has private visibility
 */
abstract contract ERC721URIStorage is ERC721, Operators {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            //return string(abi.encodePacked(base, _tokenURI));
            //Due customer requirements
            return _tokenURI;
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual override {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function setURI(uint256 tokenId, string calldata _tokenURI) external onlyOperator {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setURIBatch(uint256[] calldata tokenId, string[] calldata _tokenURI) external onlyOperator {
        require(tokenId.length == _tokenURI.length, "tokenId length is not equal to _tokenURI length");
        for (uint i = 0; i < tokenId.length; i++) {
            _setTokenURI(tokenId[i], _tokenURI[i]);
        }
    }

    address public signerAddress;

    function setSigner(address _newSigner) external onlyOwner {
        signerAddress = _newSigner;
    }

    function hashArguments(uint256 tokenId, string calldata _tokenURI)
        public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(tokenId, _tokenURI));
    }

    function getSigner(uint256 tokenId, string calldata _tokenURI, uint8 _v, bytes32 _r, bytes32 _s)
        public
        pure
        returns (address)
    {
        bytes32 msgHash = hashArguments(tokenId, _tokenURI);
        return ecrecover(msgHash, _v, _r, _s);
    }

    function isValidSignature(uint256 tokenId, string calldata _tokenURI, uint8 _v, bytes32 _r, bytes32 _s)
        public
        view
        returns (bool)
    {
        return getSigner(tokenId, _tokenURI, _v, _r, _s) == signerAddress;
    }

    /**
       * @dev Sets token URI using signature
       * This method can be called by anyone, who has signature,
       * that was created by signer role
       */
    function setURISigned(uint256 tokenId, string calldata _tokenURI, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(isValidSignature(tokenId, _tokenURI, _v, _r, _s), "Invalid signature");
        _setTokenURI(tokenId, _tokenURI);
    }

}

