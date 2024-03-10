// SPDX-License-Identifier: BUSL-1.1
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox.fi, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {AddressProvider} from "../core/AddressProvider.sol";
import {ContractsRegister} from "../core/ContractsRegister.sol";
import {ACL} from "../core/ACL.sol";

import {DieselToken} from "../tokens/DieselToken.sol";
import {LinearInterestRateModel} from "../pool/LinearInterestRateModel.sol";
import {PoolService} from "../pool/PoolService.sol";
import {CreditManager} from "../credit/CreditManager.sol";
import {CreditFilter} from "../credit/CreditFilter.sol";

import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

contract PoolDeployer is Ownable {
    struct DeployOpts {
        address addressProvider; // address of addressProvider contract
        address underlyingToken; // address of underlying token for pool and creditManager
        uint256 U_optimal; // linear interest model parameter
        uint256 R_base; // linear interest model parameter
        uint256 R_slope1; // linear interest model parameter
        uint256 R_slope2; // linear interest model parameter
        uint256 expectedLiquidityLimit; // linear interest model parameter
        uint256 minAmount; // minimal amount for credit account
        uint256 maxAmount; // maximum amount for credit account
        uint256 maxLeverage; // high bound for Leverage (x100 value)
        uint256 withdrawFee; // withdrawFee
        address defaultSwapContract; // address for Uniswap V2 compatible contract which is used during CloseAccount action
        AllowedToken[] allowedTokens;
    }

    struct AllowedToken {
        address token;
        uint256 liquidationThreshold;
    }

    AllowedToken[] allowedTokens;

    AddressProvider public addressProvider;
    PoolService public pool;
    CreditFilter public creditFilter;
    CreditManager public creditManager;
    address public root;
    uint256 public withdrawFee;

    constructor(DeployOpts memory opts) {
        addressProvider = AddressProvider(opts.addressProvider);

        for (uint256 i = 0; i < opts.allowedTokens.length; i++) {
            allowedTokens.push(opts.allowedTokens[i]);
        }

        ERC20 token = ERC20(opts.underlyingToken);
        DieselToken dieselToken = new DieselToken(
            string(abi.encodePacked("diesel ", token.name())),
            string(abi.encodePacked("d", token.symbol())),
            token.decimals()
        ); // T:[PD-1]

        LinearInterestRateModel linearModel = new LinearInterestRateModel(
            opts.U_optimal,
            opts.R_base,
            opts.R_slope1,
            opts.R_slope2
        ); // T:[PD-1]

        pool = new PoolService(
            opts.addressProvider,
            opts.underlyingToken,
            address(dieselToken),
            address(linearModel),
            opts.expectedLiquidityLimit
        );

        creditFilter = new CreditFilter(
            opts.addressProvider,
            opts.underlyingToken
        ); // T:[PD-1]

        creditManager = new CreditManager(
            opts.addressProvider,
            opts.minAmount,
            opts.maxAmount,
            opts.maxLeverage,
            address(pool),
            address(creditFilter),
            opts.defaultSwapContract
        ); // T:[PD-1]

        dieselToken.transferOwnership(address(pool));

        withdrawFee = opts.withdrawFee;
        root = ACL(addressProvider.getACL()).owner();
    }

    function configure() external onlyOwner {
        ACL acl = ACL(addressProvider.getACL());
        ContractsRegister cr = ContractsRegister(
            addressProvider.getContractsRegister()
        );

        pool.setWithdrawFee(withdrawFee);

        cr.addPool(address(pool)); // T:[PD-2]
        cr.addCreditManager(address(creditManager)); // T:[PD-2]

        pool.connectCreditManager(address(creditManager));

        for (uint256 i; i < allowedTokens.length; i++) {
            creditFilter.allowToken(
                allowedTokens[i].token,
                allowedTokens[i].liquidationThreshold
            ); // T:[PD-2]
        }

        creditFilter.connectCreditManager(address(creditManager)); // T:[PD-2]

        acl.transferOwnership(root); // T:[PD-2]
    }

    // Will be used in case of configure() revert
    function getRootBack() external onlyOwner {
        ACL acl = ACL(addressProvider.getACL()); // T:[PD-3]
        acl.transferOwnership(root);
    }

    function destoy() external onlyOwner {
        selfdestruct(msg.sender);
    }
}

