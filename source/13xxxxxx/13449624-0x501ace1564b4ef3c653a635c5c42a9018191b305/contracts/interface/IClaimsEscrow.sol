// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IERC721Enhanced.sol";

/**
 * @title IClaimsEscrow
 * @author solace.fi
 * @notice The payer of claims.
 *
 * [**Policyholders**](/docs/protocol/policy-holder) can submit claims through their policy's product contract, in the process burning the policy and converting it to a claim.
 *
 * The [**policyholder**](/docs/protocol/policy-holder) will then need to wait for a [`cooldownPeriod()`](#cooldownperiod) after which they can [`withdrawClaimsPayout()`](#withdrawclaimspayout).
 *
 * To pay the claims funds are taken from the [`Vault`](../Vault) and deducted from [**capital provider**](/docs/user-guides/capital-provider/cp-role-guide) earnings.
 *
 * Claims are **ERC721**s and abbreviated as **SCT**.
 */
interface IClaimsEscrow is IERC721Enhanced {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a new claim is received.
    event ClaimReceived(uint256 indexed claimID, address indexed claimant, uint256 amount);
    /// @notice Emitted when a claim is paid out.
    event ClaimWithdrawn(uint256 indexed claimID, address indexed claimant, uint256 amount);
    /// @notice Emitted when a claim is adjusted.
    event ClaimAdjusted(uint256 indexed claimID, address indexed claimant, uint256 oldAmount, uint256 newAmount);
    /// @notice Emitted when ETH is returned to the Vault.
    event EthReturned(uint256 amount);
    /// @notice Emitted when the cooldown period is set.
    event CooldownPeriodSet(uint256 cooldownPeriod);

    /***************************************
    CLAIM CREATION
    ***************************************/

    /**
     * @notice Receives a claim.
     * The new claim will have the same ID that the policy had and will be withdrawable after a cooldown period.
     * Only callable by active products.
     * @param policyID ID of policy to claim.
     * @param claimant Address of the claimant.
     * @param amount Amount of ETH to claim.
     */
    function receiveClaim(uint256 policyID, address claimant, uint256 amount) external payable;

    /***************************************
    CLAIM PAYOUT
    ***************************************/

    /**
     * @notice Allows claimants to withdraw their claims payout.
     * Will attempt to withdraw the full amount then burn the claim if successful.
     * Only callable by the claimant.
     * Only callable after the cooldown period has elapsed (from the time the claim was approved and processed).
     * @param claimID The ID of the claim to withdraw payout for.
     */
    function withdrawClaimsPayout(uint256 claimID) external;

    /***************************************
    CLAIM VIEW
    ***************************************/

    /// @notice Claim struct.
    struct Claim {
        uint256 amount;
        uint256 receivedAt; // used to determine withdrawability after cooldown period
    }

    /**
     * @notice Gets information about a claim.
     * @param claimID Claim to query.
     * @return info Claim info as struct.
     */
    function claim(uint256 claimID) external view returns (Claim memory info);

    /**
     * @notice Gets information about a claim.
     * @param claimID Claim to query.
     * @return amount Claim amount in ETH.
     * @return receivedAt Time claim was received at.
     */
    function getClaim(uint256 claimID) external view returns (uint256 amount, uint256 receivedAt);

    /**
     * @notice Returns true if the payout of the claim can be withdrawn.
     * @param claimID The ID to check.
     * @return status True if it is withdrawable, false if not.
     */
    function isWithdrawable(uint256 claimID) external view returns (bool status);

    /**
     * @notice The amount of time left until the payout is withdrawable.
     * @param claimID The ID to check.
     * @return time The duration in seconds.
     */
    function timeLeft(uint256 claimID) external view returns (uint256 time);

    /***************************************
    GLOBAL VIEWS
    ***************************************/

    /// @notice Tracks how much **ETH** is required to payout all claims.
    function totalClaimsOutstanding() external view returns (uint256);

    /// @notice The duration of time in seconds the user must wait between submitting a claim and withdrawing the payout.
    function cooldownPeriod() external view returns (uint256);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adjusts the value of a claim.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param claimID The claim to adjust.
     * @param value The new payout of the claim.
     */
    function adjustClaim(uint256 claimID, uint256 value) external;

    /**
     * @notice Returns **ETH** to the [`Vault`](../Vault).
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param amount Amount to pull.
     */
    function returnEth(uint256 amount) external;

    /**
     * @notice Set the cooldown duration.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param cooldownPeriod_ New cooldown duration in seconds
     */
    function setCooldownPeriod(uint256 cooldownPeriod_) external;

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * Receive function. Deposits eth.
     */
    receive() external payable;

    /**
     * Fallback function. Deposits eth.
     */
    fallback () external payable;
}

