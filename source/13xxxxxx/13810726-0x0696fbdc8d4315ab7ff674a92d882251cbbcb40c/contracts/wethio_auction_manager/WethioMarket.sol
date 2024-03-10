// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;
pragma abicoder v2; // solhint-disable-line

import "./mixins/WethioTreasuryNode.sol";
import "./mixins/roles/WethioAdminRole.sol";
import "./mixins/SendValueWithFallbackWithdraw.sol";
import "./mixins/NFTMarketAuction.sol";
import "./mixins/NFTMarketReserveAuction.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title A market for NFTs on Wethio.
 * @dev This top level file holds no data directly to ease future upgrades.
 */

contract WethioMarket is
    WethioTreasuryNode,
    WethioAdminRole,
    ReentrancyGuardUpgradeable,
    SendValueWithFallbackWithdraw,
    NFTMarketAuction,
    NFTMarketReserveAuction
{
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(address payable treasury) public initializer {
        WethioTreasuryNode._initializeWethioTreasuryNode(treasury);
        NFTMarketAuction._initializeNFTMarketAuction();
        NFTMarketReserveAuction._initializeNFTMarketReserveAuction();
    }

    /**
     * @notice Allows Wethio to update the market configuration.
     */
    function adminUpdateConfig(
        uint256 minPercentIncrementInBasisPoints,
        uint256 duration
    ) public onlyWethioAdmin {
        _updateReserveAuctionConfig(minPercentIncrementInBasisPoints, duration);
    }

    /**
     * @notice Allows Wethio to update the treasury contract address.
     */
    function adminUpdateContract(address payable treasury)
        external
        onlyWethioAdmin
    {
        _updateWethioTreasury(treasury);
    }
}

