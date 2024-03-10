// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./NFTXv3.sol";

contract NFTXv4 is NFTXv3 {
    function _mintD2(uint256 vaultId, uint256 amount)
        internal
        virtual
        override
    {
        store.d2Asset(vaultId).safeTransferFrom(
            msg.sender,
            address(this),
            amount.mul(1000)
        );
        store.xToken(vaultId).mint(msg.sender, amount);
        store.setD2Holdings(
            vaultId,
            store.d2Holdings(vaultId).add(amount.mul(1000))
        );
    }

    function _redeemD2(uint256 vaultId, uint256 amount)
        internal
        virtual
        override
    {
        store.xToken(vaultId).burnFrom(msg.sender, amount);
        store.d2Asset(vaultId).safeTransfer(msg.sender, amount.mul(1000));
        store.setD2Holdings(
            vaultId,
            store.d2Holdings(vaultId).sub(amount.mul(1000))
        );
    }
}

