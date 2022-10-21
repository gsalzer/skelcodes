// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.6;

import "./IWETH9.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/**
 * @title IVault
 * @author solace.fi
 * @notice The risk-backing capital pool.
 *
 * [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) can deposit **ETH** or **WETH** into the `Vault` to mint shares. Shares are represented as **CP tokens** aka **SCP** and extend `ERC20`. [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) should use [`depositEth()`](#depositeth) or [`depositWeth()`](#depositweth), not regular **ETH** or **WETH** transfer.
 *
 * As [**Policyholders**](/docs/protocol/policy-holder) purchase coverage, premiums will flow into the capital pool and are split amongst the [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide). If a loss event occurs in an active policy, some funds will be used to payout the claim. These events will affect the price per share but not the number or distribution of shares.
 *
 * By minting shares of the `Vault`, [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) willingly accept the risk that the whole or a part of their funds may be used payout claims. A malicious [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) could detect a loss event and try to withdraw their funds before claims are paid out. To prevent this, the `Vault` uses a cooldown mechanic such that while the [**capital provider**](/docs/user-guides/capital-provider/cp-role-guide) is not in cooldown mode (default) they can mint, send, and receive **SCP** but not withdraw **ETH**. To withdraw their **ETH**, the [**capital provider**](/docs/user-guides/capital-provider/cp-role-guide) must `startCooldown()`(#startcooldown), wait no less than `cooldownMin()`(#cooldownmin) and no more than `cooldownMax()`(#cooldownmax), then call `withdrawEth()`(#withdraweth) or `withdrawWeth()`(#withdrawweth). While in cooldown mode users cannot send or receive **SCP** and minting shares will take them out of cooldown.
 */
interface IVault is IERC20Metadata, IERC20Permit {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a user deposits funds.
    event DepositMade(address indexed depositor, uint256 indexed amount, uint256 indexed shares);
    /// @notice Emitted when a user withdraws funds.
    event WithdrawalMade(address indexed withdrawer, uint256 indexed value);
    /// @notice Emitted when funds are sent to a requestor.
    event FundsSent(uint256 value);
    /// @notice Emitted when deposits are paused.
    event Paused();
    /// @notice Emitted when deposits are unpaused.
    event Unpaused();
    /// @notice Emitted when a user enters cooldown mode.
    event CooldownStarted(address user);
    /// @notice Emitted when a user leaves cooldown mode.
    event CooldownStopped(address user);
    /// @notice Emitted when the cooldown window is set.
    event CooldownWindowSet(uint40 cooldownMin, uint40 cooldownMax);
    /// @notice Emitted when a requestor is added.
    event RequestorAdded(address requestor);
    /// @notice Emitted when a requestor is removed.
    event RequestorRemoved(address requestor);

    /***************************************
    CAPITAL PROVIDER FUNCTIONS
    ***************************************/

    /**
     * @notice Allows a user to deposit **ETH** into the `Vault`(becoming a **Capital Provider**).
     * Shares of the `Vault` (CP tokens) are minted to caller.
     * It is called when `Vault` receives **ETH**.
     * It issues the amount of token share respected to the deposit to the `recipient`.
     * Reverts if `Vault` is paused.
     * @return shares The number of shares minted.
     */
    function depositEth() external payable returns (uint256 shares);

    /**
     * @notice Allows a user to deposit **WETH** into the `Vault`(becoming a **Capital Provider**).
     * Shares of the Vault (CP tokens) are minted to caller.
     * It issues the amount of token share respected to the deposit to the `recipient`.
     * Reverts if `Vault` is paused.
     * @param amount Amount of weth to deposit.
     * @return shares The number of shares minted.
     */
    function depositWeth(uint256 amount) external returns (uint256);

    /**
     * @notice Starts the cooldown.
     */
    function startCooldown() external;

    /**
     * @notice Stops the cooldown.
     */
    function stopCooldown() external;

    /**
     * @notice Allows a user to redeem shares for **ETH**.
     * Burns **SCP** and transfers **ETH** to the [**Capital Provider**](/docs/user-guides/capital-provider/cp-role-guide).
     * @param shares Amount of shares to redeem.
     * @return value The amount in **ETH** that the shares where redeemed for.
     */
    function withdrawEth(uint256 shares) external returns (uint256 value);

    /**
     * @notice Allows a user to redeem shares for **WETH**.
     * Burns **SCP** tokens and transfers **WETH** to the [**Capital Provider**](/docs/user-guides/capital-provider/cp-role-guide).
     * @param shares amount of shares to redeem.
     * @return value The amount in **WETH** that the shares where redeemed for.
     */
    function withdrawWeth(uint256 shares) external returns (uint256 value);

    /***************************************
    CAPITAL PROVIDER VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The price of one **SCP**.
     * @return price The price in **ETH**.
     */
    function pricePerShare() external view returns (uint256 price);

    /**
     * @notice Returns the maximum redeemable shares by the `user` such that `Vault` does not go under **MCR**(Minimum Capital Requirement). May be less than their balance.
     * @param user The address of user to check.
     * @return shares The max redeemable shares by the user.
     */
    function maxRedeemableShares(address user) external view returns (uint256 shares);

    /**
     * @notice Returns the total quantity of all assets held by the `Vault`.
     * @return assets The total assets under control of this vault.
    */
    function totalAssets() external view returns (uint256 assets);

    /// @notice The minimum amount of time a user must wait to withdraw funds.
    function cooldownMin() external view returns (uint40);

    /// @notice The maximum amount of time a user must wait to withdraw funds.
    function cooldownMax() external view returns (uint40);

    /**
     * @notice The timestamp that a depositor's cooldown started.
     * @param user The depositor.
     * @return start The timestamp in seconds.
     */
    function cooldownStart(address user) external view returns (uint40 start);

    /**
     * @notice Returns true if the user is allowed to receive or send vault shares.
     * @param user User to query.
     * return status True if can transfer.
     */
    function canTransfer(address user) external view returns (bool status);

    /**
     * @notice Returns true if the user is allowed to withdraw vault shares.
     * @param user User to query.
     * return status True if can withdraw.
     */
    function canWithdraw(address user) external view returns (bool status);

    /// @notice Returns true if the vault is paused.
    function paused() external view returns (bool paused_);

    /***************************************
    REQUESTOR FUNCTIONS
    ***************************************/

    /**
     * @notice Sends **ETH** to other users or contracts.
     * Can only be called by authorized requestors.
     * @param amount Amount of **ETH** wanted.
     */
    function requestEth(uint256 amount) external;

    /**
     * @notice Returns true if the destination is authorized to request **ETH**.
     * @param dst Account to check requestability.
     * @return status True if requestor, false if not.
     */
    function isRequestor(address dst) external view returns (bool status);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Pauses deposits.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * While paused:
     * 1. No users may deposit into the Vault.
     * 2. Withdrawls can bypass cooldown.
     * 3. Only Governance may unpause.
    */
    function pause() external;

    /**
     * @notice Unpauses deposits.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
    */
    function unpause() external;

    /**
     * @notice Sets the `minimum` and `maximum` amount of time in seconds that a user must wait to withdraw funds.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param cooldownMin_ Minimum time in seconds.
     * @param cooldownMax_ Maximum time in seconds.
     */
    function setCooldownWindow(uint40 cooldownMin_, uint40 cooldownMax_) external;

    /**
     * @notice Adds requesting rights.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param requestor The requestor to grant rights.
     */
    function addRequestor(address requestor) external;

    /**
     * @notice Removes requesting rights.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param requestor The requestor to revoke rights.
     */
    function removeRequestor(address requestor) external;

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * @notice Fallback function to allow contract to receive *ETH*.
     * Does _not_ mint shares.
     */
    receive () external payable;

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     * Does _not_ mint shares.
     */
    fallback () external payable;
}

