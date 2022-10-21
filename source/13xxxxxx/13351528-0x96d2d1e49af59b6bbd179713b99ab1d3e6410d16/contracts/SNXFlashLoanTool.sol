// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAddressResolver } from "synthetix/contracts/interfaces/IAddressResolver.sol";
import { ISynthetix } from "synthetix/contracts/interfaces/ISynthetix.sol";
import { ISNXFlashLoanTool } from "./interfaces/ISNXFlashLoanTool.sol";
import { IFlashLoanReceiver } from "./interfaces/IFlashLoanReceiver.sol";
import { ILendingPoolAddressesProvider } from "./interfaces/ILendingPoolAddressesProvider.sol";
import { ILendingPool } from "./interfaces/ILendingPool.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/// @author Ganesh Gautham Elango
/// @title Burn sUSD debt with SNX using a flash loan
contract SNXFlashLoanTool is ISNXFlashLoanTool, IFlashLoanReceiver, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Synthetix address resolver
    IAddressResolver public immutable addressResolver;
    /// @dev SNX token contract
    IERC20 public immutable snx;
    /// @dev sUSD token contract
    IERC20 public immutable sUSD;
    /// @dev Aave LendingPoolAddressesProvider contract
    ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
    /// @dev Aave LendingPool contract
    ILendingPool public immutable override LENDING_POOL;
    /// @dev Approved DEX address
    address public immutable override approvedExchange;
    /// @dev Aave LendingPool referral code
    uint16 public constant referralCode = 185;

    /// @dev Constructor
    /// @param _snxResolver Synthetix AddressResolver address
    /// @param _provider Aave LendingPoolAddressesProvider address
    /// @param _approvedExchange Approved DEX address to swap on
    constructor(
        address _snxResolver,
        address _provider,
        address _approvedExchange
    ) {
        IAddressResolver synthetixResolver = IAddressResolver(_snxResolver);
        addressResolver = synthetixResolver;
        IERC20 _snx = IERC20(synthetixResolver.getAddress("ProxyERC20"));
        snx = _snx;
        sUSD = IERC20(synthetixResolver.getAddress("ProxyERC20sUSD"));
        ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(_provider);
        ADDRESSES_PROVIDER = provider;
        LENDING_POOL = ILendingPool(provider.getLendingPool());
        approvedExchange = _approvedExchange;
        _snx.safeApprove(_approvedExchange, type(uint256).max);
    }

    /// @notice Burn sUSD debt with SNX using a flash loan
    /// @dev To burn all sUSD debt, pass in type(uint256).max for sUSDAmount
    /// @param sUSDAmount Amount of sUSD debt to burn (set to type(uint256).max to burn all debt)
    /// @param snxAmount Amount of SNX to sell in order to burn sUSD debt
    /// @param exchangeData Calldata to call exchange with
    function burn(
        uint256 sUSDAmount,
        uint256 snxAmount,
        bytes calldata exchangeData
    ) external override {
        address[] memory assets = new address[](1);
        assets[0] = address(sUSD);
        uint256[] memory amounts = new uint256[](1);
        // If sUSDAmount is max, get the sUSD debt of the user, otherwise just use sUSDAmount
        amounts[0] = sUSDAmount == type(uint256).max
            ? ISynthetix(addressResolver.getAddress("Synthetix")).debtBalanceOf(msg.sender, "sUSD")
            : sUSDAmount;
        uint256[] memory modes = new uint256[](1);
        // Mode is set to 0 so the flash loan doesn't incur any debt
        modes[0] = 0;
        // Initiate flash loan
        LENDING_POOL.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            abi.encode(snxAmount, msg.sender, exchangeData),
            referralCode
        );
        emit Burn(msg.sender, amounts[0], snxAmount);
    }

    /// @dev Aave flash loan callback. Receives the token amounts and gives it back + premiums.
    /// @param assets The addresses of the assets being flash-borrowed
    /// @param amounts The amounts amounts being flash-borrowed
    /// @param premiums Fees to be paid for each asset
    /// @param initiator The msg.sender to Aave
    /// @param params Arbitrary packed params to pass to the receiver as extra information
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(LENDING_POOL), "SNXFlashLoanTool: Invalid msg.sender");
        require(initiator == address(this), "SNXFlashLoanTool: Invalid initiator");
        (uint256 snxAmount, address user, bytes memory exchangeData) = abi.decode(params, (uint256, address, bytes));
        // Send sUSD to user to burn
        sUSD.transfer(user, amounts[0]);
        // Burn sUSD with flash loaned amount
        ISynthetix(addressResolver.getAddress("Synthetix")).burnSynthsOnBehalf(user, amounts[0]);
        // Transfer specified SNX amount from user
        snx.safeTransferFrom(user, address(this), snxAmount);
        // Swap SNX to sUSD on the approved DEX
        (bool success, ) = approvedExchange.call(exchangeData);
        require(success, "SNXFlashLoanTool: Swap failed");
        // sUSD amount received from swap
        uint256 receivedSUSD = sUSD.balanceOf(address(this));
        // Approve owed sUSD amount to Aave
        uint256 amountOwing = amounts[0].add(premiums[0]);
        sUSD.safeApprove(msg.sender, amountOwing);
        // If there is leftover sUSD on this contract, transfer it to the user
        if (amountOwing < receivedSUSD) {
            sUSD.safeTransfer(user, receivedSUSD.sub(amountOwing));
        }
        return true;
    }

    /// @notice Transfer a tokens balance left on this contract to the owner
    /// @dev Can only be called by owner
    /// @param token Address of token to transfer the balance of
    function transferToken(address token) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}

