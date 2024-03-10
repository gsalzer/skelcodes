// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./NFTX.sol";

contract NFTXv2 is NFTX {
    /* function transferERC721(uint256 vaultId, uint256 tokenId, address to)
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
    } */

    function _mint(uint256 vaultId, uint256[] memory nftIds, bool isDualOp)
        internal
        virtual
        override
    {
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            uint256 nftId = nftIds[i];
            require(isEligible(vaultId, nftId), "Not eligible");
            require(
                store.nft(vaultId).ownerOf(nftId) != address(this),
                "Already owner"
            );
            store.nft(vaultId).transferFrom(msg.sender, address(this), nftId);
            require(
                store.nft(vaultId).ownerOf(nftId) == address(this),
                "Not received"
            );
            if (store.shouldReserve(vaultId, nftId)) {
                store.reservesAdd(vaultId, nftId);
            } else {
                store.holdingsAdd(vaultId, nftId);
            }
        }
        if (!isDualOp) {
            uint256 amount = nftIds.length.mul(10**18);
            store.xToken(vaultId).mint(msg.sender, amount);
        }
    }
}

