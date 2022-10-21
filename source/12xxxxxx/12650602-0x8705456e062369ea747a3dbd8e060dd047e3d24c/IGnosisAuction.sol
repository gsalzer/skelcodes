// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

interface IGnosisAuction {
    function settleAuction(uint256 auctionId) external returns (bytes32 clearingOrder);
}

