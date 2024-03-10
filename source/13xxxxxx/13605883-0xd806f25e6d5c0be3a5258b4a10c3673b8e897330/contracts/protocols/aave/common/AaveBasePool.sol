// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IZap} from "contracts/lpaccount/Imports.sol";
import {
    IAssetAllocation,
    IDetailedERC20,
    IERC20
} from "contracts/common/Imports.sol";
import {SafeERC20} from "contracts/libraries/Imports.sol";
import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

import {ILendingPool, DataTypes} from "./interfaces/ILendingPool.sol";
import {
    IAaveIncentivesController
} from "./interfaces/IAaveIncentivesController.sol";
import {AaveConstants} from "contracts/protocols/aave/Constants.sol";

abstract contract AaveBasePool is IZap, AaveConstants {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address internal immutable UNDERLYER_ADDRESS;
    address internal immutable POOL_ADDRESS;

    // TODO: think about including the AToken address to conserve gas
    // TODO: consider using IDetailedERC20 as the type instead of address for underlyer

    constructor(address underlyerAddress, address lendingAddress) public {
        UNDERLYER_ADDRESS = underlyerAddress;
        POOL_ADDRESS = lendingAddress;
    }

    /// @param amounts array of underlyer amounts
    function deployLiquidity(uint256[] calldata amounts) external override {
        require(amounts.length == 1, "INVALID_AMOUNTS");
        IERC20(UNDERLYER_ADDRESS).safeApprove(POOL_ADDRESS, 0);
        IERC20(UNDERLYER_ADDRESS).safeApprove(POOL_ADDRESS, amounts[0]);
        _deposit(amounts[0]);
    }

    /// @param amount LP token amount
    function unwindLiquidity(uint256 amount, uint8 index) external override {
        require(index == 0, "INVALID_INDEX");
        _withdraw(amount);
    }

    function claim() external virtual override {
        IAaveIncentivesController controller =
            IAaveIncentivesController(STAKED_INCENTIVES_CONTROLLER_ADDRESS);
        address[] memory assets = new address[](1);
        assets[0] = _getATokenAddress(UNDERLYER_ADDRESS);
        uint256 amount = controller.getRewardsBalance(assets, address(this));
        controller.claimRewards(assets, amount, address(this));
    }

    function getLpTokenBalance(address account)
        external
        view
        override
        returns (uint256)
    {
        address aTokenAddress = _getATokenAddress(UNDERLYER_ADDRESS);
        return IERC20(aTokenAddress).balanceOf(account);
    }

    function sortedSymbols() public view override returns (string[] memory) {
        // so we have to hardcode the number here
        string[] memory symbols = new string[](1);
        symbols[0] = IDetailedERC20(UNDERLYER_ADDRESS).symbol();
        return symbols;
    }

    function assetAllocations()
        public
        view
        virtual
        override
        returns (string[] memory)
    {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = BASE_NAME;
        return allocationNames;
    }

    function erc20Allocations()
        public
        view
        virtual
        override
        returns (IERC20[] memory)
    {
        IERC20[] memory allocations = new IERC20[](1);
        allocations[0] = IERC20(UNDERLYER_ADDRESS);
        return allocations;
    }

    function _deposit(uint256 amount) internal virtual {
        ILendingPool(POOL_ADDRESS).deposit(
            UNDERLYER_ADDRESS,
            amount,
            address(this),
            0
        );
    }

    function _withdraw(uint256 lpBalance) internal virtual {
        ILendingPool(POOL_ADDRESS).withdraw(
            UNDERLYER_ADDRESS,
            lpBalance,
            address(this)
        );
    }

    function _getATokenAddress(address underlyerAddress)
        internal
        view
        returns (address)
    {
        DataTypes.ReserveData memory reserveData =
            ILendingPool(POOL_ADDRESS).getReserveData(underlyerAddress);
        return reserveData.aTokenAddress;
    }
}

