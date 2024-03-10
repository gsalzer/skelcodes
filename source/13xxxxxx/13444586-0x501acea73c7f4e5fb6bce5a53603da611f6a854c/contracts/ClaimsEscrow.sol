// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Governable.sol";
import "./ERC721Enhanced.sol";
import "./interface/IRegistry.sol";
import "./interface/IVault.sol";
import "./interface/IPolicyManager.sol";
import "./interface/IClaimsEscrow.sol";

/**
 * @title ClaimsEscrow
 * @author solace.fi
 * @notice The payer of claims.
 *
 * [**Policyholders**](/docs/protocol/policy-holder) can submit claims through their policy's product contract, in the process burning the policy and converting it to a claim.
 *
 * The [**policyholder**](/docs/protocol/policy-holder) will then need to wait for a [`cooldownPeriod()`](#cooldownperiod) after which they can [`withdrawClaimsPayout()`](#withdrawclaimspayout).
 *
 * To pay the claims funds are taken from the [`Vault`](./Vault) and deducted from [**capital provider**](/docs/user-guides/capital-provider/cp-role-guide) earnings.
 *
 * Claims are **ERC721**s and abbreviated as **SCT**.
 */
contract ClaimsEscrow is ERC721Enhanced, IClaimsEscrow, ReentrancyGuard, Governable {
    using Address for address;
    using SafeERC20 for IERC20;

    /// @notice The duration of time in seconds the user must wait between submitting a claim and withdrawing the payout.
    uint256 internal _cooldownPeriod = 1 hours;

    /// @notice Registry of protocol contract addresses.
    IRegistry private _registry;

    /// @notice mapping of claimID to Claim object
    mapping (uint256 => Claim) internal _claims;

    /// @notice Tracks how much **ETH** is required to payout all claims
    uint256 internal _totalClaimsOutstanding;

    /**
     * @notice Constructs the ClaimsEscrow contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param registry_ The address of the [`Registry`](./Registry).
     */
    constructor(address governance_, address registry_) ERC721Enhanced("Solace Claim", "SCT") Governable(governance_) {
        require(registry_ != address(0x0), "zero address registry");
        _registry = IRegistry(registry_);
    }

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
    function receiveClaim(uint256 policyID, address claimant, uint256 amount) external payable override {
        require(IPolicyManager(_registry.policyManager()).productIsActive(msg.sender), "!product");
        require(claimant != address(0x0), "zero address claimant");
        uint256 tco = _totalClaimsOutstanding + amount;
        _totalClaimsOutstanding = tco;
        uint256 bal = address(this).balance;
        if(bal < tco) IVault(payable(_registry.vault())).requestEth(tco - bal);
        // Add claim to claims mapping
        _claims[policyID] = Claim({
            amount: amount,
            receivedAt: block.timestamp
        });
        _mint(claimant, policyID);
        emit ClaimReceived(policyID, claimant, amount);
    }

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
    function withdrawClaimsPayout(uint256 claimID) external override nonReentrant tokenMustExist(claimID) {
        require(_isApprovedOrOwner(msg.sender, claimID), "!claimant");
        require(block.timestamp >= _claims[claimID].receivedAt + _cooldownPeriod, "cooldown period has not elapsed");

        uint256 amount = _claims[claimID].amount;
        // if not enough eth, request more
        if(amount > address(this).balance) {
            IVault(payable(_registry.vault())).requestEth(amount - address(this).balance);
        }
        // if still not enough eth, partial withdraw
        if(amount > address(this).balance) {
            uint256 balance = address(this).balance;
            _totalClaimsOutstanding -= balance;
            _claims[claimID].amount -= balance;
            Address.sendValue(payable(msg.sender), balance);
            emit ClaimWithdrawn(claimID, msg.sender, balance);
        }
        // if enough eth, full withdraw and delete claim
        else {
            _totalClaimsOutstanding -= amount;
            delete _claims[claimID];
            _burn(claimID);
            Address.sendValue(payable(msg.sender), amount);
            emit ClaimWithdrawn(claimID, msg.sender, amount);
        }
    }

    /***************************************
    CLAIM VIEW
    ***************************************/

    /**
     * @notice Gets information about a claim.
     * @param claimID Claim to query.
     * @return info Claim info as struct.
     */
    function claim(uint256 claimID) external view override tokenMustExist(claimID) returns (Claim memory info) {
        return _claims[claimID];
    }

    /**
     * @notice Gets information about a claim.
     * @param claimID Claim to query.
     * @return amount Claim amount in ETH.
     * @return receivedAt Time claim was received at.
     */
    function getClaim(uint256 claimID) external view override tokenMustExist(claimID) returns (uint256 amount, uint256 receivedAt) {
        Claim memory info = _claims[claimID];
        return (info.amount, info.receivedAt);
    }

    /**
     * @notice Returns true if the payout of the claim can be withdrawn.
     * @param claimID The ID to check.
     * @return status True if it is withdrawable, false if not.
     */
    function isWithdrawable(uint256 claimID) external view override returns (bool status) {
        return _exists(claimID) && block.timestamp >= _claims[claimID].receivedAt + _cooldownPeriod;
    }

    /**
     * @notice The amount of time left until the payout is withdrawable.
     * @param claimID The ID to check.
     * @return time The duration in seconds.
     */
    function timeLeft(uint256 claimID) external view override tokenMustExist(claimID) returns (uint256 time) {
        uint256 end = _claims[claimID].receivedAt + _cooldownPeriod;
        if(block.timestamp >= end) return 0;
        return end - block.timestamp;
    }

    /***************************************
    GLOBAL VIEWS
    ***************************************/

    /// @notice Tracks how much **ETH** is required to payout all claims.
    function totalClaimsOutstanding() external view override returns (uint256) {
        return _totalClaimsOutstanding;
    }

    /// @notice The duration of time in seconds the user must wait between submitting a claim and withdrawing the payout.
    function cooldownPeriod() external view override returns (uint256) {
        return _cooldownPeriod;
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adjusts the value of a claim.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param claimID The claim to adjust.
     * @param value The new payout of the claim.
     */
    function adjustClaim(uint256 claimID, uint256 value) external override onlyGovernance tokenMustExist(claimID) {
        _totalClaimsOutstanding = _totalClaimsOutstanding - _claims[claimID].amount + value;
        uint256 oldAmount = _claims[claimID].amount;
        _claims[claimID].amount = value;
        emit ClaimAdjusted(claimID, ownerOf(claimID), oldAmount, value);
    }

    /**
     * @notice Returns **ETH** to the [`Vault`](../Vault).
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param amount Amount to pull.
     */
    function returnEth(uint256 amount) external override onlyGovernance nonReentrant {
        Address.sendValue(payable(_registry.vault()), amount);
        emit EthReturned(amount);
    }

    /**
     * @notice Set the cooldown duration.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param cooldownPeriod_ The new cooldown duration in seconds.
     */
    function setCooldownPeriod(uint256 cooldownPeriod_) external override onlyGovernance {
        _cooldownPeriod = cooldownPeriod_;
        emit CooldownPeriodSet(cooldownPeriod_);
    }

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * Receive function. Deposits eth.
     */
    receive() external payable override { }

    /**
     * Fallback function. Deposits eth.
     */
    fallback () external payable override { }
}

