// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IERC721Enhanced.sol";


/**
 * @title IOptionsFarming
 * @author solace.fi
 * @notice Distributes options to farmers.
 *
 * Rewards are accumulated by farmers for participating in farms. Rewards can be redeemed for options with 1:1 reward:[**SOLACE**](./SOLACE). Options can be exercised by paying `strike price` **ETH** before `expiry` to receive `rewardAmount` [**SOLACE**](./SOLACE).
 *
 * The `strike price` is calculated by either:
 *   - The current market price of [**SOLACE**](./SOLACE) * `swap rate` as determined by the [**SOLACE**](./SOLACE)-**ETH** Uniswap pool.
 *   - The floor price of [**SOLACE**](./SOLACE)/**USD** converted to **ETH** using a **ETH**-**USD** Uniswap pool.
 */
interface IOptionsFarming is IERC721Enhanced {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when an option is created.
    event OptionCreated(uint256 optionID);
    /// @notice Emitted when an option is exercised.
    event OptionExercised(uint256 optionID);
    /// @notice Emitted when solace is set.
    event SolaceSet(address solace);
    /// @notice Emitted when farm controller is set.
    event FarmControllerSet(address farmController);
    /// @notice Emitted when [**SOLACE**](../SOLACE)-**ETH** pool is set.
    event SolaceEthPoolSet(address solaceEthPool);
    /// @notice Emitted when **ETH**-**USD** pool is set.
    event EthUsdPoolSet(address ethUsdPool);
    /// @notice Emitted when [**SOLACE**](../SOLACE)-**ETH** twap interval is set.
    event SolaceEthTwapIntervalSet(uint32 twapInterval);
    /// @notice Emitted when **ETH**-**USD** twap interval is set.
    event EthUsdTwapIntervalSet(uint32 twapInterval);
    /// @notice Emitted when expiry duration is set.
    event ExpiryDurationSet(uint256 expiryDuration);
    /// @notice Emitted when swap rate is set.
    event SwapRateSet(uint16 swapRate);
    /// @notice Emitted when fund receiver is set.
    event ReceiverSet(address receiver);
    /// @notice Emitted when the solace-usd price floor is set.
    event PriceFloorSet(uint256 priceFloor);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Native [**SOLACE**](../SOLACE) Token.
    function solace() external view returns (address solace_);

    /// @notice The [`FarmController(../FarmController).
    function farmController() external view returns (address controller_);

    /// @notice The receiver for options payments.
    function receiver() external view returns (address receiver_);

    /// @notice Amount of time in seconds into the future that new options will expire.
    function expiryDuration() external view returns (uint256 expiryDuration_);

    /// @notice Total number of options ever created.
    function numOptions() external view returns (uint256 numOptions_);

    /// @notice The uniswap [**SOLACE**](../SOLACE)-**ETH** pool for calculating twap.
    function solaceEthPool() external view returns (address solaceEthPool_);

    /// @notice The uniswap **ETH**-**USD** pool for calculating twap.
    function ethUsdPool() external view returns (address ethUsdPool_);

    /// @notice Interval in seconds to calculate time weighted average price in strike price.
    /// Used in [**SOLACE**](../SOLACE)-**ETH** twap.
    function solaceEthTwapInterval() external view returns (uint32 twapInterval_);

    /// @notice Interval in seconds to calculate time weighted average price in strike price.
    /// Used in **ETH**-**USD** twap.
    function ethUsdTwapInterval() external view returns (uint32 twapInterval_);

    /// @notice The relative amount of the eth value that a user must pay, measured in BPS.
    /// Only applies to the [**SOLACE**](../SOLACE)-**ETH** pool.
    function swapRate() external view returns (uint16 swapRate_);

    /// @notice The floor price of [**SOLACE**](./SOLACE) measured in **USD**.
    /// Specifically, whichever stablecoin is in the **ETH**-**USD** pool.
    function priceFloor() external view returns (uint256 priceFloor_);

    /**
     * @notice The amount of [**SOLACE**](./SOLACE) that a user is owed if any.
     * @param user The user.
     * @return amount The amount.
     */
    function unpaidSolace(address user) external view returns (uint256 amount);

    struct Option {
        uint256 rewardAmount; // The amount of SOLACE out.
        uint256 strikePrice;  // The amount of ETH in.
        uint256 expiry;       // The expiration timestamp.
    }

    /**
     * @notice Get information about an option.
     * @param optionID The ID of the option to query.
     * @return rewardAmount The amount of [**SOLACE**](../SOLACE) out.
     * @return strikePrice The amount of **ETH** in.
     * @return expiry The expiration timestamp.
     */
    function getOption(uint256 optionID) external view returns (uint256 rewardAmount, uint256 strikePrice, uint256 expiry);

    /**
     * @notice Calculate the strike price for an amount of [**SOLACE**](../SOLACE).
     * @param rewardAmount Amount of [**SOLACE**](../SOLACE).
     * @return strikePrice Strike Price in **ETH**.
     */
    function calculateStrikePrice(uint256 rewardAmount) external view returns (uint256 strikePrice);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Creates an option for the given `rewardAmount`.
     * Must be called by the [`FarmController(./FarmController).
     * @param recipient The recipient of the option.
     * @param rewardAmount The amount to reward in the Option.
     * @return optionID The ID of the newly minted option.
     */
    function createOption(address recipient, uint256 rewardAmount) external returns (uint256 optionID);

    /**
     * @notice Exercises an Option.
     * `msg.sender` must pay `option.strikePrice` **ETH**.
     * `msg.sender` will receive `option.rewardAmount` [**SOLACE**](../SOLACE).
     * Can only be called by the Option owner or approved.
     * Can only be called before `option.expiry`.
     * @param optionID The ID of the Option to exercise.
     */
    function exerciseOption(uint256 optionID) external payable;

    /**
     * @notice Exercises an Option in part.
     * `msg.sender` will pay `msg.value` **ETH**.
     * `msg.sender` will receive a fair amount of [**SOLACE**](../SOLACE).
     * Can only be called by the Option owner or approved.
     * Can only be called before `option.expiry`.
     * @param optionID The ID of the Option to exercise.
     */
    function exerciseOptionInPart(uint256 optionID) external payable;

    /**
     * @notice Transfers the unpaid [**SOLACE**](../SOLACE) to the user.
     */
    function withdraw() external;

    /**
     * @notice Sends this contract's **ETH** balance to `receiver`.
     */
    function sendValue() external;

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
    * @notice Sets the [**SOLACE**](../SOLACE) native token.
    * Can only be called by the current [**governor**](/docs/protocol/governance).
    * @param solace_ The address of the [**SOLACE**](../SOLACE) contract.
    */
    function setSolace(address solace_) external;

    /**
     * @notice Sets the [`FarmController(../FarmController) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param controller The address of the new [`FarmController(../FarmController).
     */
    function setFarmController(address controller) external;

    /**
     * @notice Sets the recipient for Option payments.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param receiver The new recipient.
     */
    function setReceiver(address payable receiver) external;

    /**
     * @notice Sets the time into the future that new Options will expire.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param expiryDuration_ The duration in seconds.
     */
    function setExpiryDuration(uint256 expiryDuration_) external;

    /**
     * @notice Sets the [**SOLACE**](../SOLACE)-**ETH** pool for twap calculations.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pool The address of the pool.
     * @param solaceIsToken0 True if [**SOLACE**](./SOLACE) is token0 in the pool, false otherwise.
     * @param interval The interval of the twap.
     */
    function setSolaceEthPool(address pool, bool solaceIsToken0, uint32 interval) external;

    /**
     * @notice Sets the **ETH**-**USD** pool for twap calculations.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pool The address of the pool.
     * @param usdIsToken0 True if **USD** is token0 in the pool, false otherwise.
     * @param interval The interval of the twap.
     * @param priceFloor_ The floor price in the **USD** stablecoin.
     */
    function setEthUsdPool(address pool, bool usdIsToken0, uint32 interval, uint256 priceFloor_) external;

    /**
     * @notice Sets the interval for [**SOLACE**](../SOLACE)-**ETH** twap calculations.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param interval The interval of the twap.
     */
    function setSolaceEthTwapInterval(uint32 interval) external;

    /**
     * @notice Sets the interval for **ETH**-**USD** twap calculations.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param interval The interval of the twap.
     */
    function setEthUsdTwapInterval(uint32 interval) external;

    /**
     * @notice Sets the swap rate for prices in the [**SOLACE**](../SOLACE)-**ETH** pool.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param swapRate_ The new swap rate.
     */
    function setSwapRate(uint16 swapRate_) external;

    /**
     * @notice Sets the floor price of [**SOLACE**](./SOLACE) measured in **USD**.
     * Specifically, whichever stablecoin is in the **ETH**-**USD** pool.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param priceFloor_ The new floor price.
     */
    function setPriceFloor(uint256 priceFloor_) external;

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

