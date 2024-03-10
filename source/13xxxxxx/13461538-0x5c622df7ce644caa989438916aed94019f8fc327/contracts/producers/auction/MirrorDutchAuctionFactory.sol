// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IOwnableEvents} from "../../lib/Ownable.sol";
import {IPausableEvents} from "../../lib/Pausable.sol";
import {ITreasuryConfig} from "../../interface/ITreasuryConfig.sol";
import {ITributaryRegistry} from "../../interface/ITributaryRegistry.sol";
import {IMirrorTreasury} from "../../interface/IMirrorTreasury.sol";
import {MirrorDutchAuctionProxy} from "./MirrorDutchAuctionProxy.sol";
import {IMirrorDutchAuctionLogic} from "./interface/IMirrorDutchAuctionLogic.sol";

interface IMirrorDutchAuctionFactory {
    /// @notice Emitted when a proxy is deployed
    event MirrorDutchAuctionProxyDeployed(
        address proxy,
        address operator,
        address logic,
        bytes initializationData
    );

    function deploy(
        address operator,
        address tributary,
        IMirrorDutchAuctionLogic.AuctionConfig memory auctionConfig
    ) external returns (address proxy);
}

/**
 * @title MirrorDutchAuctionFactory
 * @author MirrorXYZ
 * This contract implements a factory to deploy a simple Dutch Auction
 * proxies with a price reduction mechanism at fixed intervals.
 */
contract MirrorDutchAuctionFactory is
    IMirrorDutchAuctionFactory,
    IOwnableEvents,
    IPausableEvents
{
    /// @notice The contract that holds the Dutch Auction logic
    address public logic;

    /// @notice The contract that holds the treasury configuration
    address public treasuryConfig;

    /// @notice Address that holds the tributary registry for Mirror treasury
    address public tributaryRegistry;

    constructor(
        address logic_,
        address treasuryConfig_,
        address tributaryRegistry_
    ) {
        logic = logic_;
        treasuryConfig = treasuryConfig_;
        tributaryRegistry = tributaryRegistry_;
    }

    function deploy(
        address operator,
        address tributary,
        IMirrorDutchAuctionLogic.AuctionConfig memory auctionConfig
    ) external override returns (address proxy) {
        bytes memory initializationData = abi.encodeWithSelector(
            IMirrorDutchAuctionLogic.initialize.selector,
            operator,
            treasuryConfig,
            auctionConfig
        );

        proxy = address(
            new MirrorDutchAuctionProxy{
                salt: keccak256(
                    abi.encode(
                        operator,
                        auctionConfig.recipient,
                        auctionConfig.nft
                    )
                )
            }(logic, initializationData)
        );

        emit MirrorDutchAuctionProxyDeployed(
            proxy,
            operator,
            logic,
            initializationData
        );

        ITributaryRegistry(tributaryRegistry).registerTributary(
            proxy,
            tributary
        );
    }
}

