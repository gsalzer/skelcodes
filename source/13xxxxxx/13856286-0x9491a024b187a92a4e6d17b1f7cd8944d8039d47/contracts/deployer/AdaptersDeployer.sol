// SPDX-License-Identifier: BUSL-1.1
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox.fi, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {AddressProvider} from "../core/AddressProvider.sol";
import {ACL} from "../core/ACL.sol";

import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {ICreditFilter} from "../interfaces/ICreditFilter.sol";

import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

import {CurveV1Adapter} from "../adapters/CurveV1.sol";
import {UniswapV2Adapter} from "../adapters/UniswapV2.sol";
import {UniswapV3Adapter} from "../adapters/UniswapV3.sol";
import {YearnAdapter} from "../adapters/YearnV2.sol";

contract AdaptersDeployer is Ownable {
    struct AdapterConfig {
        address targetContract;
        // Adapter types:
        //   UNISWAP_V2 = 1;
        //   UNISWAP_V3 = 2;
        //   CURVE_V1 = 3;
        //   LP_YEARN = 4;
        uint256 adapterType;
    }

    struct DeployOpts {
        address addressProvider;
        address creditManager;
        AdapterConfig[] adapters;
    }

    struct Adapter {
        address adapter;
        address targetContract;
    }

    AddressProvider public addressProvider;
    ICreditFilter public creditFilter;
    Adapter[] public adapters;
    address public root;

    constructor(DeployOpts memory opts) {
        addressProvider = AddressProvider(opts.addressProvider); // T:[PD-3]

        creditFilter = ICreditManager(opts.creditManager).creditFilter(); // T:[PD-3]

        address newAdapter; // T:[PD-3]
        for (uint256 i = 0; i < opts.adapters.length; i++) {
            if (opts.adapters[i].adapterType == Constants.UNISWAP_V2) {
                newAdapter = address(
                    new UniswapV2Adapter(
                        opts.creditManager,
                        opts.adapters[i].targetContract
                    )
                ); // T:[PD-3]
            } else if (opts.adapters[i].adapterType == Constants.UNISWAP_V3) {
                newAdapter = address(
                    new UniswapV3Adapter(
                        opts.creditManager,
                        opts.adapters[i].targetContract
                    )
                ); // T:[PD-3]
            } else if (opts.adapters[i].adapterType == Constants.CURVE_V1) {
                newAdapter = address(
                    new CurveV1Adapter(
                        opts.creditManager,
                        opts.adapters[i].targetContract
                    )
                ); // T:[PD-3]
            } else if (opts.adapters[i].adapterType == Constants.LP_YEARN) {
                newAdapter = address(
                    new YearnAdapter(
                        opts.creditManager,
                        opts.adapters[i].targetContract
                    )
                );
            } // T:[PD-3]

            Adapter memory adapter = Adapter(
                newAdapter,
                opts.adapters[i].targetContract
            ); // T:[PD-3]

            adapters.push(adapter); // T:[PD-3]
        }
        root = ACL(addressProvider.getACL()).owner(); // T:Todo
    }

    function connectAdapters()
        external
        onlyOwner // T:[PD-3]
    {
        ACL acl = ACL(addressProvider.getACL()); // T:[PD-3]

        for (uint256 i; i < adapters.length; i++) {
            creditFilter.allowContract(
                adapters[i].targetContract,
                adapters[i].adapter
            );
        }

        //        creditFilter.allowPlugin(addressProvider.getLeveragedActions());
        acl.transferOwnership(root); // T:[PD-3]
        // Discussable
        //        selfdestruct(msg.sender);
    }

    // Will be used in case of connectAdapters() revert
    function getRootBack() external onlyOwner {
        ACL acl = ACL(addressProvider.getACL()); // T:[PD-3]
        acl.transferOwnership(root);
    }

    function destoy() external onlyOwner {
        selfdestruct(msg.sender);
    }
}

