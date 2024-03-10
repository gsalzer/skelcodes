// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IPolicyManager.sol";
import "./IFarm.sol";


/**
 * @title ISptFarm
 * @author solace.fi
 * @notice Rewards [**Policyholders**](/docs/protocol/policy-holder) in [**Options**](../OptionFarming) for staking their [**Policies**](./PolicyManager).
 *
 * Over the course of `startTime` to `endTime`, the farm distributes `rewardPerSecond` [**Options**](../OptionFarming) to all farmers split relative to the value of the policies they have deposited.
 *
 * Note that you should deposit your policies via [`depositPolicy()`](#depositpolicy) or [`depositPolicySigned()`](#depositpolicysigned). Raw `ERC721.transfer()` will not be recognized.
 */
interface ISptFarm is IFarm {

    /***************************************
    EVENTS
    ***************************************/

    // Emitted when a policy is deposited onto the farm.
    event PolicyDeposited(address indexed user, uint256 policyID);
    // Emitted when a policy is withdrawn from the farm.
    event PolicyWithdrawn(address indexed user, uint256 policyID);
    /// @notice Emitted when rewardPerSecond is changed.
    event RewardsSet(uint256 rewardPerSecond);
    /// @notice Emitted when the end time is changed.
    event FarmEndSet(uint256 endTime);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice
    function policyManager() external view returns (address policyManager_);

    /// @notice Last time rewards were distributed or farm was updated.
    function lastRewardTime() external view returns (uint256 timestamp);

    /// @notice Accumulated rewards per share, times 1e12.
    function accRewardPerShare() external view returns (uint256 acc);

    /// @notice Value of policies a user deposited.
    function userStaked(address user) external view returns (uint256 amount);

    /// @notice Value of policies deposited by all farmers.
    function valueStaked() external view returns (uint256 amount);

    /// @notice Information about a deposited policy.
    function policyInfo(uint256 policyID) external view returns (address depositor, uint256 value);

    /**
     * @notice Returns the count of [**policies**](./PolicyManager) that a user has deposited onto the farm.
     * @param user The user to check count for.
     * @return count The count of deposited [**policies**](./PolicyManager).
     */
    function countDeposited(address user) external view returns (uint256 count);

    /**
     * @notice Returns the list of [**policies**](./PolicyManager) that a user has deposited onto the farm and their values.
     * @param user The user to list deposited policies.
     * @return policyIDs The list of deposited policies.
     * @return policyValues The values of the policies.
     */
    function listDeposited(address user) external view returns (uint256[] memory policyIDs, uint256[] memory policyValues);

    /**
     * @notice Returns the ID of a [**Policies**](./PolicyManager) that a user has deposited onto a farm and its value.
     * @param user The user to get policyID for.
     * @param index The farm-based index of the token.
     * @return policyID The ID of the deposited [**policy**](./PolicyManager).
     * @return policyValue The value of the [**policy**](./PolicyManager).
     */
    function getDeposited(address user, uint256 index) external view returns (uint256 policyID, uint256 policyValue);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit a [**policy**](./PolicyManager).
     * User must `ERC721.approve()` or `ERC721.setApprovalForAll()` first.
     * @param policyID The ID of the policy to deposit.
     */
    function depositPolicy(uint256 policyID) external;

    /**
     * @notice Deposit a [**policy**](./PolicyManager) using permit.
     * @param depositor The depositing user.
     * @param policyID The ID of the policy to deposit.
     * @param deadline Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function depositPolicySigned(address depositor, uint256 policyID, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @notice Deposit multiple [**policies**](./PolicyManager).
     * User must `ERC721.approve()` or `ERC721.setApprovalForAll()` first.
     * @param policyIDs The IDs of the policies to deposit.
     */
    function depositPolicyMulti(uint256[] memory policyIDs) external;

    /**
     * @notice Deposit multiple [**policies**](./PolicyManager) using permit.
     * @param depositors The depositing users.
     * @param policyIDs The IDs of the policies to deposit.
     * @param deadlines Times the transactions must go through before.
     * @param vs secp256k1 signatures
     * @param rs secp256k1 signatures
     * @param ss secp256k1 signatures
     */
    function depositPolicySignedMulti(address[] memory depositors, uint256[] memory policyIDs, uint256[] memory deadlines, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss) external;

    /**
     * @notice Withdraw a [**policy**](./PolicyManager).
     * Can only withdraw policies you deposited.
     * @param policyID The ID of the policy to withdraw.
     */
    function withdrawPolicy(uint256 policyID) external;

    /**
     * @notice Withdraw multiple [**policies**](./PolicyManager).
     * Can only withdraw policies you deposited.
     * @param policyIDs The IDs of the policies to withdraw.
     */
    function withdrawPolicyMulti(uint256[] memory policyIDs) external;

    /**
     * @notice Burns expired policies.
     * @param policyIDs The list of expired policies.
     */
    function updateActivePolicies(uint256[] calldata policyIDs) external;
}

