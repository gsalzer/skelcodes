// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IVault.sol";
import "./IFarm.sol";


/**
 * @title CpFarm
 * @author solace.fi
 * @notice Rewards [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) in [**SOLACE**](../SOLACE) for providing capital in the [`Vault`](../Vault).
 *
 * Over the course of `startTime` to `endTime`, the farm distributes `rewardPerSecond` [**SOLACE**](../SOLACE) to all farmers split relative to the amount of [**SCP**](../Vault) they have deposited.
 *
 * Users can become [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) by depositing **ETH** into the [`Vault`](../Vault), receiving [**SCP**](../Vault) in the process. [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) can then deposit their [**SCP**](../Vault) via [`depositCp()`](#depositcp) or [`depositCpSigned()`](#depositcpsigned). Alternatively users can bypass the [`Vault`](../Vault) and stake their **ETH** via [`depositEth()`](#depositeth).
 *
 * Users can withdraw their rewards via [`withdrawRewards()`](#withdrawrewards).
 *
 * Users can withdraw their [**SCP**](../Vault) via [`withdrawCp()`](#withdrawcp).
 *
 * Note that transferring in **ETH** will mint you shares, but transferring in **WETH** or [**SCP**](../Vault) will not. These must be deposited via functions in this contract. Misplaced funds cannot be rescued.
 */
interface ICpFarm is IFarm {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when CP tokens are deposited onto the farm.
    event CpDeposited(address indexed user, uint256 amount);
    /// @notice Emitted when ETH is deposited onto the farm.
    event EthDeposited(address indexed user, uint256 amount);
    /// @notice Emitted when CP tokens are withdrawn from the farm.
    event CpWithdrawn(address indexed user, uint256 amount);
    /// @notice Emitted when rewardPerSecond is changed.
    event RewardsSet(uint256 rewardPerSecond);
    /// @notice Emitted when the end time is changed.
    event FarmEndSet(uint256 endTime);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Vault contract.
    function vault() external view returns (address vault_);

    /// @notice WETH contract.
    function weth() external view returns (address weth_);

    /// @notice Last time rewards were distributed or farm was updated.
    function lastRewardTime() external view returns (uint256 timestamp);

    /// @notice Accumulated rewards per share, times 1e12.
    function accRewardPerShare() external view returns (uint256 acc);

    /// @notice The amount of [**SCP**](../Vault) tokens a user deposited.
    function userStaked(address user) external view returns (uint256 amount);

    /// @notice Value of tokens staked by all farmers.
    function valueStaked() external view returns (uint256 amount);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit some [**CP tokens**](../Vault).
     * User must `ERC20.approve()` first.
     * @param amount The deposit amount.
     */
    function depositCp(uint256 amount) external;

    /**
     * @notice Deposit some [**CP tokens**](../Vault) using `ERC2612.permit()`.
     * @param depositor The depositing user.
     * @param amount The deposit amount.
     * @param deadline Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function depositCpSigned(address depositor, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @notice Deposit some **ETH**.
     */
    function depositEth() external payable;

    /**
     * @notice Deposit some **WETH**.
     * @param amount The amount of **WETH** to deposit.
     */
    function depositWeth(uint256 amount) external;

    /**
     * @notice Withdraw some [**CP tokens**](../Vault).
     * User will receive amount of deposited tokens and accumulated rewards.
     * Can only withdraw as many tokens as you deposited.
     * @param amount The withdraw amount.
     */
    function withdrawCp(uint256 amount) external;

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * Receive function. Deposits eth.
     */
    receive () external payable;

    /**
     * Fallback function. Deposits eth.
     */
    fallback () external payable;
}

