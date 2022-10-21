// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./NFTX.sol";

contract NFTXv2 is NFTX {
    function transferERC721(uint256 vaultId, uint256 tokenId, address to)
        public
        virtual
        onlyOwner
    {
        store.nft(vaultId).transferFrom(address(this), to, tokenId);
    }

    function createVault(
        address _xTokenAddress,
        address _assetAddress,
        bool _isD2Vault
    ) public virtual override nonReentrant returns (uint256) {
        if (_xTokenAddress != _assetAddress && _isD2Vault) {
            return 0;
        }
        return 0;
    }
}

