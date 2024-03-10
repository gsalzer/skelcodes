// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {DataTypes} from "../DataTypes.sol";

/**
 * @notice the lending pool contract
 */
interface ILendingPool {
    /**
     * @notice Deposits a certain amount of an asset into the protocol, minting
     * the same amount of corresponding aTokens, and transferring them
     * to the onBehalfOf address.
     * E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @dev When depositing, the LendingPool contract must have at least an
     * allowance() of amount for the asset being deposited.
     * During testing, you can use the referral code: 0.
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     * wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     * is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     * 0 if the action is executed directly by the user, without any middle-man
     */
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning
     * the equivalent aTokens owned.
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC,
     * burning the 100 aUSDC
     * @dev Ensure you set the relevant ERC20 allowance of the aToken,
     * before calling this function, so the LendingPool
     * contract can burn the associated aTokens.
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     * - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     * wants to receive it on his own wallet, or a different address if the beneficiary is a
     * different wallet
     * @return The final amount withdrawn
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);
}

