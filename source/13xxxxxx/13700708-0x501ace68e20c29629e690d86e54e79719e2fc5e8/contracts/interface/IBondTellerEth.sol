// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IBondTeller.sol";


/**
 * @title IBondTellerEth
 * @author solace.fi
 * @notice A bond teller that accepts **ETH** and **WETH** as payment.
 *
 * Bond tellers allow users to buy bonds. After vesting for `vestingTerm`, bonds can be redeemed for [**SOLACE**](./SOLACE) or [**xSOLACE**](./xSOLACE). Payments are made in **ETH** or **WETH** which is sent to the underwriting pool and used to back risk.
 *
 * Bonds can be purchased via [`depositEth()`](#depositeth), [`depositWeth()`](#depositweth), or [`depositWethSigned()`](#depositwethsigned). Bonds are represented as ERC721s, can be viewed with [`bonds()`](#bonds), and redeemed with [`redeem()`](#redeem).
 */
interface IBondTellerEth is IBondTeller {

    /**
     * @notice Create a bond by depositing **ETH**.
     * Principal will be transferred from `msg.sender` using `allowance`.
     * @param minAmountOut The minimum **SOLACE** or **xSOLACE** out.
     * @param depositor The bond recipient, default msg.sender.
     * @param stake True to stake, false to not stake.
     * @return payout The amount of SOLACE or xSOLACE in the bond.
     * @return bondID The ID of the newly created bond.
     */
    function depositEth(
        uint256 minAmountOut,
        address depositor,
        bool stake
    ) external payable returns (uint256 payout, uint256 bondID);

    /**
     * @notice Create a bond by depositing `amount` **WETH**.
     * **WETH** will be transferred from `msg.sender` using `allowance`.
     * @param amount Amount of **WETH** to deposit.
     * @param minAmountOut The minimum **SOLACE** or **xSOLACE** out.
     * @param depositor The bond recipient, default msg.sender.
     * @param stake True to stake, false to not stake.
     * @return payout The amount of SOLACE or xSOLACE in the bond.
     * @return bondID The ID of the newly created bond.
     */
    function depositWeth(
        uint256 amount,
        uint256 minAmountOut,
        address depositor,
        bool stake
    ) external returns (uint256 payout, uint256 bondID);

    /**
     * @notice Create a bond by depositing `amount` **WETH**.
     * **WETH** will be transferred from `depositor` using `permit`.
     * Note that not all **WETH**s have a permit function, in which case this function will revert.
     * @param amount Amount of **WETH** to deposit.
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
    function depositWethSigned(
        uint256 amount,
        uint256 minAmountOut,
        address depositor,
        bool stake,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 payout, uint256 bondID);

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * @notice Fallback function to allow contract to receive *ETH*.
     * Deposits **ETH** and creates bond.
     */
    receive () external payable;

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     * Deposits **ETH** and creates bond.
     */
    fallback () external payable;
}

