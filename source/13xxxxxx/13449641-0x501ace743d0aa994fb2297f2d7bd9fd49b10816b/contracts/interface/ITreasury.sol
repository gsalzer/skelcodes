// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title ITreasury
 * @author solace.fi
 * @notice The war chest of Castle Solace.
 *
 * As policies are purchased, premiums will flow from [**policyholders**](/docs/protocol/policy-holder) to the `Treasury`. By default `Treasury` reroutes 100% of the premiums into the [`Vault`](../Vault) where it is split amongst the [**capital providers**](/docs/user-guides/capital-provider/cp-role-guide).
 *
 * If a [**policyholder**](/docs/protocol/policy-holder) updates or cancels a policy they may receive a refund. Refunds will be paid out from the [`Vault`](../Vault). If there are not enough funds to pay out the refund in whole, the [`unpaidRefunds()`](#unpaidrefunds) will be tracked and can be retrieved later via [`withdraw()`](#withdraw).
 *
 * [**Governance**](/docs/protocol/governance) can change the premium recipients via [`setPremiumRecipients()`](#setpremiumrecipients). This can be used to add new building blocks to Castle Solace or enact a protocol fee. Premiums can be stored in the `Treasury` and managed with a number of functions.
 */
interface ITreasury {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a token is spent.
    event FundsSpent(address token, uint256 amount, address recipient);
    /// @notice Emitted when premium recipients are set.
    event RecipientsSet();
    /// @notice Emitted when premiums are routed.
    event PremiumsRouted(uint256 amount);
    /// @notice Emitted when ETH is refunded to a user.
    event EthRefunded(address user, uint256 amount);

    /***************************************
    FUNDS IN
    ***************************************/

    /**
     * @notice Routes the **premiums** to the `recipients`.
     * Each recipient will receive a `recipientWeight / weightSum` portion of the premiums.
     * Will be called by products with `msg.value = premium`.
     */
    function routePremiums() external payable;

    /**
     * @notice Number of premium recipients.
     * @return count The number of premium recipients.
     */
    function numPremiumRecipients() external view returns (uint256 count);

    /**
     * @notice Gets the premium recipient at `index`.
     * @param index Index to query, enumerable `[0, numPremiumRecipients()-1]`.
     * @return recipient The receipient address.
     */
    function premiumRecipient(uint256 index) external view returns (address recipient);

    /**
     * @notice Gets the weight of the recipient.
     * @param index Index to query, enumerable `[0, numPremiumRecipients()]`.
     * @return weight The recipient weight.
     */
    function recipientWeight(uint256 index) external view returns (uint32 weight);

    /**
     * @notice Gets the sum of all premium recipient weights.
     * @return weight The sum of weights.
     */
    function weightSum() external view returns (uint32 weight);

    /***************************************
    FUNDS OUT
    ***************************************/

    /**
     * @notice Refunds some **ETH** to the user.
     * Will attempt to send the entire `amount` to the `user`.
     * If there is not enough available at the moment, it is recorded and can be pulled later via [`withdraw()`](#withdraw).
     * Can only be called by active products.
     * @param user The user address to send refund amount.
     * @param amount The amount to send the user.
     */
    function refund(address user, uint256 amount) external;

    /**
     * @notice The amount of **ETH** that a user is owed if any.
     * @param user The user.
     * @return amount The amount.
     */
    function unpaidRefunds(address user) external view returns (uint256 amount);

    /**
     * @notice Transfers the unpaid refunds to the user.
     */
    function withdraw() external;

    /***************************************
    FUND MANAGEMENT
    ***************************************/

    /**
     * @notice Sets the premium recipients and their weights.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param recipients The premium recipients, plus an implicit `address(this)` at the end.
     * @param weights The recipient weights.
     */
    function setPremiumRecipients(address payable[] calldata recipients, uint32[] calldata weights) external;

    /**
     * @notice Spends an **ERC20** token or **ETH**.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param token The address of the token to spend.
     * @param amount The amount of the token to spend.
     * @param recipient The address of the token receiver.
     */
    function spend(address token, uint256 amount, address recipient) external;

    /**
     * @notice Wraps some **ETH** into **WETH**.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param amount The amount to wrap.
     */
    function wrap(uint256 amount) external;

    /**
     * @notice Unwraps some **WETH** into **ETH**.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param amount The amount to unwrap.
     */
    function unwrap(uint256 amount) external;

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     */
    receive() external payable;

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     */
    fallback () external payable;
}

