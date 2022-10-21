// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IBondTeller.sol";


/**
 * @title IBondTellerErc20
 * @author solace.fi
 * @notice A bond teller that accepts an ERC20 as payment.
 *
 * Bond tellers allow users to buy bonds. After vesting for `vestingTerm`, bonds can be redeemed for [**SOLACE**](./SOLACE) or [**xSOLACE**](./xSOLACE). Payments are made in `principal` which is sent to the underwriting pool and used to back risk.
 *
 * Bonds can be purchased via [`deposit()`](#deposit) or [`depositSigned()`](#depositsigned). Bonds are represented as ERC721s, can be viewed with [`bonds()`](#bonds), and redeemed with [`redeem()`](#redeem).
 */
interface IBondTellerErc20 is IBondTeller {

    /**
     * @notice Create a bond by depositing `amount` of `principal`.
     * Principal will be transferred from `msg.sender` using `allowance`.
     * @param amount Amount of principal to deposit.
     * @param minAmountOut The minimum **SOLACE** or **xSOLACE** out.
     * @param depositor The bond recipient, default msg.sender.
     * @param stake True to stake, false to not stake.
     * @return payout The amount of SOLACE or xSOLACE in the bond.
     * @return bondID The ID of the newly created bond.
     */
    function deposit(
        uint256 amount,
        uint256 minAmountOut,
        address depositor,
        bool stake
    ) external returns (uint256 payout, uint256 bondID);

    /**
     * @notice Create a bond by depositing `amount` of `principal`.
     * Principal will be transferred from `depositor` using `permit`.
     * Note that not all ERC20s have a permit function, in which case this function will revert.
     * @param amount Amount of principal to deposit.
     * @param minAmountOut The minimum **SOLACE** or **xSOLACE** out.
     * @param depositor The bond recipient, default msg.sender.
     * @param stake True to stake, false to not stake.
     * @param deadline Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     * @return payout The amount of SOLACE or xSOLACE in the bond.
     * @return bondID The ID of the newly created bond.
     */
    function depositSigned(
        uint256 amount,
        uint256 minAmountOut,
        address depositor,
        bool stake,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 payout, uint256 bondID);
}

