// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "../interfaces/IStrategy.sol";

contract EnglishAuction is IStrategy {
    function canClaim(
        address proxy,
        uint256 deadline,
        bytes memory params,
        address bidder,
        uint256 bidPrice,
        address bestBidder,
        uint256 bestBidPrice,
        uint256
    ) external view override returns (bool) {
        if (proxy == address(0)) {
            return bidder == bestBidder && bidPrice == bestBidPrice && deadline < block.timestamp;
        } else {
            uint256 startPrice = abi.decode(params, (uint256));
            require(startPrice > 0, "SHOYU: INVALID_START_PRICE");

            return bidPrice >= startPrice && deadline < block.timestamp;
        }
    }

    function canBid(
        address proxy,
        uint256 deadline,
        bytes memory params,
        address,
        uint256 bidPrice,
        address,
        uint256 bestBidPrice,
        uint256
    ) external view override returns (bool) {
        if (proxy == address(0)) {
            uint256 startPrice = abi.decode(params, (uint256));
            require(startPrice > 0, "SHOYU: INVALID_START_PRICE");

            return block.timestamp <= deadline && bidPrice >= startPrice && bidPrice > bestBidPrice;
        } else {
            return false;
        }
    }
}

