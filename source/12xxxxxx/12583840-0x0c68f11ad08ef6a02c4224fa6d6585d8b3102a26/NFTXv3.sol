// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./NFTXv2.sol";

contract NFTXv3 is NFTXv2 {
    function requestMint(uint256 vaultId, uint256[] memory nftIds)
        public
        payable
        virtual
        override
        nonReentrant
    {
        onlyOwnerIfPaused(1);
        require(store.allowMintRequests(vaultId), "Not allowed");
        // TODO: implement bounty + fees
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            require(
                store.nft(vaultId).ownerOf(nftIds[i]) != address(this),
                "Already owner"
            );
            store.nft(vaultId).transferFrom(
                msg.sender,
                address(this),
                nftIds[i]
            );
            require(
                store.nft(vaultId).ownerOf(nftIds[i]) == address(this),
                "Not received"
            );
            store.setRequester(vaultId, nftIds[i], msg.sender);
        }
        emit MintRequested(vaultId, nftIds, msg.sender);
    }
}

