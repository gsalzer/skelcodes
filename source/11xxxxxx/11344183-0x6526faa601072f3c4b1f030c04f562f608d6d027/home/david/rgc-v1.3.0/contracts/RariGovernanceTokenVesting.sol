/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

import "./RariGovernanceToken.sol";

/**
 * @title RariGovernanceTokenVesting
 * @author David Lucid <david@rari.capital> (https://github.com/davidlucid)
 * @notice RariGovernanceTokenVesting distributes private RGT (Rari Governance Token) allocations to team/advisors/etc. with a vesting schedule.
 */
contract RariGovernanceTokenVesting is Initializable, Ownable {
    using SafeMath for uint256;

    /**
     * @dev Initializer that configures private vesting start and end timestamps.
     */
    function initialize(uint256 _privateVestingStartTimestamp) public initializer {
        Ownable.initialize(msg.sender);
        privateVestingStartTimestamp = _privateVestingStartTimestamp;
        privateVestingEndTimestamp = _privateVestingStartTimestamp.add(PRIVATE_VESTING_PERIOD);
    }

    /**
     * @dev The RariGovernanceToken contract.
     */
    RariGovernanceToken rariGovernanceToken;

    /**
     * @dev Sets the RariGovernanceToken distributed by ths RariGovernanceTokenDistributor.
     * @param governanceToken The new RariGovernanceToken contract.
     */
    function setGovernanceToken(RariGovernanceToken governanceToken) external onlyOwner {
        require(address(governanceToken) != address(0), "New governance token contract cannot be the zero address.");
        rariGovernanceToken = governanceToken;
    }

    /**
     * @notice Length in seconds of the distribution period.
     */
    uint256 public privateVestingStartTimestamp;

    /**
     * @notice Length in seconds of the distribution period.
     */
    uint256 public constant PRIVATE_VESTING_PERIOD = 2 * 365 * 86400;

    /**
     * @notice Length in seconds of the distribution period.
     */
    uint256 public privateVestingEndTimestamp;

    /**
     * @dev Sets the `amount` of RGT privately allocated to `holder`.
     * @param holder The new RariGovernanceToken contract.
     */
    function setPrivateRgtAllocation(address holder, uint256 amount) external onlyOwner {
        require(holder != address(0), "Holder cannot be the zero address.");
        require(amount >= _privateRgtClaimed[holder], "Allocation amount must be greater than or equal to the amount claimed by this holder.");
        _privateRgtAllocated = _privateRgtAllocated.sub(privateRgtAllocations[holder]).add(amount);
        require(_privateRgtAllocated <= FINAL_PRIVATE_RGT_ALLOCATION, "Total RGT privately allocated cannot exceed the final private RGT allocation.");
        privateRgtAllocations[holder] = amount;
    }

    /**
     * @notice Returns the RGT transfer fee for team/advisors/etc. (scaled by 1e18).
     */
    function getPrivateRgtClaimFee(uint256 timestamp) public view returns (uint256) {
        if (timestamp <= privateVestingStartTimestamp) return 1e18;
        if (timestamp >= privateVestingEndTimestamp) return 0;
        return uint256(1e18).mul(privateVestingEndTimestamp.sub(timestamp)).div(PRIVATE_VESTING_PERIOD);
    }

    /**
     * @notice Total and final quantity of all RGT to be privately allocated.
     */
    uint256 public constant FINAL_PRIVATE_RGT_ALLOCATION = 1250000e18;

    /**
     * @notice Current quantity of RGT that has been privately allocated.
     */
    uint256 private _privateRgtAllocated;

    /**
     * @dev Maps team/advisor/etc. addresses to private RGT distribution quantities.
     */
    mapping(address => uint256) public privateRgtAllocations;

    /**
     * @dev Maps team/advisor/etc. addresses to claimed quantities of private RGT allocations.
     */
    mapping(address => uint256) private _privateRgtClaimed;

    /**
     * @dev Event emitted when `claimed` RGT is claimed by `holder`.
     */
    event PrivateClaim(address holder, uint256 claimed, uint256 transferred, uint256 burned);

    /**
     * @notice Returns the quantity of unclaimed RGT allocated privately to `holder`.
     * @param holder The holder of the unclaimed RGT allocated privately.
     * @return The quantity of unclaimed RGT.
     */
    function getUnclaimedPrivateRgt(address holder) public view returns (uint256) {
        return privateRgtAllocations[holder].sub(_privateRgtClaimed[holder]);
    }

    /**
     * @notice Internal function to claim `amount` unclaimed RGT allocated privately to `holder` (without validating `amount`).
     * @param holder The holder of the unclaimed RGT allocated privately.
     * @param amount The amount of RGT to claim.
     */
    function _claimPrivateRgt(address holder, uint256 amount) internal {
        uint256 burnRgt = amount.mul(getPrivateRgtClaimFee(block.timestamp)).div(1e18);
        uint256 transferRgt = amount.sub(burnRgt);
        _privateRgtClaimed[holder] = _privateRgtClaimed[holder].add(amount);
        require(rariGovernanceToken.transfer(holder, transferRgt), "Failed to transfer RGT from vesting reserve.");
        rariGovernanceToken.burn(burnRgt);
        emit PrivateClaim(holder, amount, transferRgt, burnRgt);
    }

    /**
     * @notice Claims `amount` unclaimed RGT allocated privately to `msg.sender`.
     * @param amount The amount of RGT to claim.
     */
    function claimPrivateRgt(uint256 amount) external {
        uint256 unclaimedRgt = getUnclaimedPrivateRgt(msg.sender);
        require(amount <= unclaimedRgt, "This amount is greater than the unclaimed RGT allocated privately.");
        _claimPrivateRgt(msg.sender, amount);
    }

    /**
     * @notice Claims all unclaimed RGT allocated privately to `msg.sender`.
     */
    function claimAllPrivateRgt() external {
        uint256 unclaimedRgt = getUnclaimedPrivateRgt(msg.sender);
        require(unclaimedRgt > 0, "Unclaimed RGT allocated privately not greater than 0.");
        _claimPrivateRgt(msg.sender, unclaimedRgt);
    }

    /**
     * @dev Forwards all RGT to a new RariGovernanceTokenVesting contract.
     * @param newContract The new RariGovernanceTokenVesting contract.
     */
    function upgrade(address newContract) external onlyOwner {
        rariGovernanceToken.transfer(newContract, rariGovernanceToken.balanceOf(address(this)));
    }
}

