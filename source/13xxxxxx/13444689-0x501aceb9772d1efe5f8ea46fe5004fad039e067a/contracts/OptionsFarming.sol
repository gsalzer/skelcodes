// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interface/UniswapV3/IUniswapV3Pool.sol";
import "./libraries/UniswapV3/TickMath.sol";
import "./libraries/UniswapV3/FixedPoint96.sol";
import "./libraries/UniswapV3/FullMath.sol";
import "./Governable.sol";
import "./ERC721Enhanced.sol";
import "./interface/ISOLACE.sol";
import "./interface/IFarmController.sol";
import "./interface/IOptionsFarming.sol";


/**
 * @title OptionsFarming
 * @author solace.fi
 * @notice Distributes options to farmers.
 *
 * Rewards are accumulated by farmers for participating in farms. Rewards can be redeemed for options with 1:1 reward:[**SOLACE**](./SOLACE). Options can be exercised by paying `strike price` **ETH** before `expiry` to receive `rewardAmount` [**SOLACE**](./SOLACE).
 *
 * The `strike price` is calculated by either:
 *   - The current market price of [**SOLACE**](./SOLACE) * `swap rate` as determined by the [**SOLACE**](./SOLACE)-**ETH** Uniswap pool.
 *   - The floor price of [**SOLACE**](./SOLACE)/**USD** converted to **ETH** using a **ETH**-**USD** Uniswap pool.
 */
contract OptionsFarming is ERC721Enhanced, IOptionsFarming, ReentrancyGuard, Governable {
    using SafeERC20 for IERC20;

    /// @notice Native SOLACE Token.
    ISOLACE internal _solace;

    // farm controller
    IFarmController internal _controller;

    // receiver for options payments
    address payable internal _receiver;

    // amount of time in seconds into the future that new options will expire
    uint256 internal _expiryDuration;

    // total number of options ever created
    uint256 internal _numOptions;

    /// @dev _options[optionID] => Option info.
    mapping(uint256 => Option) internal _options;

    // the uniswap [**SOLACE**](../SOLACE)-**ETH** pool for calculating twap
    IUniswapV3Pool internal _solaceEthPool;

    // the uniswap **ETH**-**USD** pool for calculating twap
    IUniswapV3Pool internal _ethUsdPool;

    // interval in seconds to calculate time weighted average price in strike price
    // used in [**SOLACE**](../SOLACE)-**ETH** twap
    uint32 internal _solaceEthTwapInterval;

    // interval in seconds to calculate time weighted average price in strike price
    // used in **ETH**-**USD** twap
    uint32 internal _ethUsdTwapInterval;

    // the relative amount of the eth value that a user must pay, measured in BPS
    uint16 internal _swapRate;

    // true if solace is token 0 of the [**SOLACE**](../SOLACE)-**ETH** pool. used in twap calculation
    bool internal _solaceIsToken0;

    // true if usd is token 0 of the **ETH**-**USD** pool. used in twap calculation
    bool internal _usdIsToken0;

    // the floor price of [**SOLACE**](./SOLACE) measured in **USD**.
    // specifically, whichever stablecoin is in the **ETH**-**USD** pool.
    uint256 internal _priceFloor;

    // The amount of **SOLACE** that a user is owed if any.
    mapping(address => uint256) internal _unpaidSolace;

    /**
     * @notice Constructs the `OptionsFarming` contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) ERC721Enhanced("Solace Options Mining", "SOM") Governable(governance_) {
        _expiryDuration = 30 days;
        _solaceEthTwapInterval = 1 hours;
        _ethUsdTwapInterval = 1 hours;
        _swapRate = 10000; // 100%
        _priceFloor = type(uint256).max;
        _numOptions = 0;
        // start zero, set later
        _solace = ISOLACE(address(0x0));
        _solaceEthPool = IUniswapV3Pool(address(0x0));
        _ethUsdPool = IUniswapV3Pool(address(0x0));
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Native [**SOLACE**](./SOLACE) Token.
    function solace() external view override returns (address solace_) {
        return address(_solace);
    }

    // @notice The [`FarmController(./FarmController).
    function farmController() external view override returns (address controller_) {
        return address(_controller);
    }

    /// @notice The receiver for options payments.
    function receiver() external view override returns (address receiver_) {
        return _receiver;
    }

    /// @notice Amount of time in seconds into the future that new options will expire.
    function expiryDuration() external view override returns (uint256 expiryDuration_) {
        return _expiryDuration;
    }

    /// @notice Total number of options ever created.
    function numOptions() external view override returns (uint256 numOptions_) {
        return _numOptions;
    }

    /// @notice The uniswap [**SOLACE**](../SOLACE)-**ETH** pool for calculating twap.
    function solaceEthPool() external view override returns (address solaceEthPool_) {
        return address(_solaceEthPool);
    }

    /// @notice The uniswap **ETH**-**USD** pool for calculating twap.
    function ethUsdPool() external view override returns (address ethUsdPool_) {
        return address(_ethUsdPool);
    }

    /// @notice Interval in seconds to calculate time weighted average price in strike price.
    // used in [**SOLACE**](./SOLACE)-**ETH** twap.
    function solaceEthTwapInterval() external view override returns (uint32 twapInterval_) {
        return _solaceEthTwapInterval;
    }

    /// @notice Interval in seconds to calculate time weighted average price in strike price.
    // used in **ETH**-**USD** twap.
    function ethUsdTwapInterval() external view override returns (uint32 twapInterval_) {
        return _ethUsdTwapInterval;
    }

    /// @notice The relative amount of the eth value that a user must pay, measured in BPS.
    function swapRate() external view override returns (uint16 swapRate_) {
        return _swapRate;
    }

    /// @notice The floor price of [**SOLACE**](./SOLACE) measured in **USD**.
    /// Specifically, whichever stablecoin is in the **ETH**-**USD** pool.
    function priceFloor() external view override returns (uint256 priceFloor_) {
        return _priceFloor;
    }

    /**
     * @notice The amount of [**SOLACE**](./SOLACE) that a user is owed if any.
     * @param user The user.
     * @return amount The amount.
     */
    function unpaidSolace(address user) external view override returns (uint256 amount) {
        return _unpaidSolace[user];
    }

    /**
     * @notice Get information about an option.
     * @param optionID The ID of the option to query.
     * @return rewardAmount The amount of **SOLACE** out.
     * @return strikePrice The amount of **ETH** in.
     * @return expiry The expiration timestamp.
     */
    function getOption(uint256 optionID) external view override tokenMustExist(optionID) returns (uint256 rewardAmount, uint256 strikePrice, uint256 expiry) {
        Option storage option = _options[optionID];
        return (option.rewardAmount, option.strikePrice, option.expiry);
    }

    /**
     * @notice Calculate the strike price for an amount of [**SOLACE**](./SOLACE).
     * SOLACE and at least one pool must be set.
     * @param rewardAmount Amount of [**SOLACE**](./SOLACE).
     * @return strikePrice Strike Price in **ETH**.
     */
    function calculateStrikePrice(uint256 rewardAmount) public view override returns (uint256 strikePrice) {
        require(address(_solace) != address(0x0), "solace not set");
        if(address(_solaceEthPool) != address(0x0)) {
            return _calculateSolaceEthPrice(rewardAmount);
        } else if (address(_ethUsdPool) != address(0x0)) {
            return _calculateEthUsdPrice(rewardAmount);
        } else {
            revert("pools not set");
        }
    }

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
    function createOption(address recipient, uint256 rewardAmount) external override returns (uint256 optionID) {
        require(msg.sender == address(_controller), "!farmcontroller");
        require(rewardAmount > 0, "no zero value options");
        // create option
        Option memory option = Option({
            rewardAmount: rewardAmount,
            strikePrice: calculateStrikePrice(rewardAmount),
            expiry: block.timestamp + _expiryDuration
        });
        optionID = ++_numOptions; // autoincrement from 1
        _options[optionID] = option;
        _mint(recipient, optionID);
        emit OptionCreated(optionID);
        return optionID;
    }

    /**
     * @notice Exercises an Option.
     * `msg.sender` must pay `option.strikePrice` **ETH**.
     * `msg.sender` will receive `option.rewardAmount` [**SOLACE**](./SOLACE).
     * Can only be called by the Option owner or approved.
     * Can only be called before `option.expiry`.
     * @param optionID The ID of the Option to exercise.
     */
    function exerciseOption(uint256 optionID) external payable override nonReentrant {
        require(_isApprovedOrOwner(msg.sender, optionID), "!owner");
        Option storage option = _options[optionID];
        // check msg.value
        require(msg.value >= option.strikePrice, "insufficient payment");
        // check timestamp
        require(block.timestamp <= option.expiry, "expired");
        // burn option
        uint256 rewardAmount = option.rewardAmount;
        _burn(optionID);
        // transfer SOLACE
        _transferSolace(msg.sender, rewardAmount);
        // transfer msg.value
        _sendValue();
        emit OptionExercised(optionID);
    }

    /**
     * @notice Exercises an Option in part.
     * `msg.sender` will pay `msg.value` **ETH**.
     * `msg.sender` will receive a fair amount of [**SOLACE**](../SOLACE).
     * Can only be called by the Option owner or approved.
     * Can only be called before `option.expiry`.
     * @param optionID The ID of the Option to exercise.
     */
    function exerciseOptionInPart(uint256 optionID) external payable override nonReentrant {
        require(_isApprovedOrOwner(msg.sender, optionID), "!owner");
        Option storage option = _options[optionID];
        // check timestamp
        require(block.timestamp <= option.expiry, "expired");
        // calculate solace out
        uint256 solaceOut = option.rewardAmount * msg.value / option.strikePrice;
        if(solaceOut >= option.rewardAmount) {
            // burn option if exercised in full
            solaceOut = option.rewardAmount;
            _burn(optionID);
        } else {
            // decrease amounts if exercised in part
            option.rewardAmount -= solaceOut;
            option.strikePrice -= msg.value;
        }
        // transfer SOLACE
        _transferSolace(msg.sender, solaceOut);
        // transfer msg.value
        _sendValue();
        emit OptionExercised(optionID);
    }

    /**
     * @notice Transfers the unpaid [**SOLACE**](./SOLACE) to the user.
     */
    function withdraw() external override nonReentrant {
        _transferSolace(msg.sender, 0);
    }

    /**
     * @notice Sends this contract's **ETH** balance to `receiver`.
     */
    function sendValue() external override {
        _sendValue();
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [**SOLACE**](../SOLACE) native token.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param solace_ The address of the [**SOLACE**](../SOLACE) contract.
     */
    function setSolace(address solace_) external override onlyGovernance {
        _solace = ISOLACE(solace_);
        _solaceEthPool = IUniswapV3Pool(address(0x0)); // reset
        emit SolaceSet(solace_);
    }

    /**
     * @notice Sets the [`FarmController(./FarmController) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param controller The address of the new [`FarmController(./FarmController).
     */
    function setFarmController(address controller) external override onlyGovernance {
        _controller = IFarmController(controller);
        emit FarmControllerSet(controller);
    }

    /**
     * @notice Sets the recipient for Option payments.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param receiver_ The new recipient.
     */
    function setReceiver(address payable receiver_) external override onlyGovernance {
        _receiver = receiver_;
        emit ReceiverSet(receiver_);
        _sendValue();
    }

    /**
     * @notice Sets the time into the future that new Options will expire.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param expiryDuration_ The duration in seconds.
     */
    function setExpiryDuration(uint256 expiryDuration_) external override onlyGovernance {
        _expiryDuration = expiryDuration_;
        emit ExpiryDurationSet(expiryDuration_);
    }

    /**
     * @notice Sets the [**SOLACE**](../SOLACE)-**ETH** pool for twap calculations.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pool The address of the pool.
     * @param solaceIsToken0 True if [**SOLACE**](./SOLACE) is token0 in the pool, false otherwise.
     * @param interval The interval of the twap.
     */
    function setSolaceEthPool(address pool, bool solaceIsToken0, uint32 interval) external override onlyGovernance {
        _solaceEthPool = IUniswapV3Pool(pool);
        _solaceIsToken0 = solaceIsToken0;
        emit SolaceEthPoolSet(pool);
        _solaceEthTwapInterval = interval;
        emit SolaceEthTwapIntervalSet(interval);
    }

    /**
     * @notice Sets the **ETH**-**USD** pool for twap calculations.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pool The address of the pool.
     * @param usdIsToken0 True if **USD** is token0 in the pool, false otherwise.
     * @param interval The interval of the twap.
     * @param priceFloor_ The floor price in the **USD** stablecoin.
     */
    function setEthUsdPool(address pool, bool usdIsToken0, uint32 interval, uint256 priceFloor_) external override onlyGovernance {
        _ethUsdPool = IUniswapV3Pool(pool);
        _usdIsToken0 = usdIsToken0;
        emit EthUsdPoolSet(pool);
        _ethUsdTwapInterval = interval;
        emit EthUsdTwapIntervalSet(interval);
        // also set this here in case we switch from usdc (6 decimals) to dai (18 decimals)
        // we dont want to give out cheap solace
        _priceFloor = priceFloor_;
        emit PriceFloorSet(priceFloor_);
    }

    /**
     * @notice Sets the interval for [**SOLACE**](./SOLACE) twap calculations.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param interval The interval of the twap.
     */
    function setSolaceEthTwapInterval(uint32 interval) external override onlyGovernance {
        _solaceEthTwapInterval = interval;
        emit SolaceEthTwapIntervalSet(interval);
    }

    /**
     * @notice Sets the interval for **ETH**-**USD** twap calculations.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param interval The interval of the twap.
     */
    function setEthUsdTwapInterval(uint32 interval) external override onlyGovernance {
        _ethUsdTwapInterval = interval;
        emit EthUsdTwapIntervalSet(interval);
    }

    /**
     * @notice Sets the swap rate for prices in the [**SOLACE**](../SOLACE)-**ETH** pool.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param swapRate_ The new swap rate.
     */
    function setSwapRate(uint16 swapRate_) external override onlyGovernance {
        _swapRate = swapRate_;
        emit SwapRateSet(swapRate_);
    }

    /**
     * @notice Sets the floor price of [**SOLACE**](./SOLACE) measured in **USD**.
     * Specifically, whichever stablecoin is in the **ETH**-**USD** pool.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param priceFloor_ The new floor price.
     */
    function setPriceFloor(uint256 priceFloor_) external override onlyGovernance {
        _priceFloor = priceFloor_;
        emit PriceFloorSet(priceFloor_);
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Calculate the strike price for an amount of [**SOLACE**](./SOLACE).
     * Uses the [**SOLACE**](../SOLACE)-**ETH** uniswap pool.
     * @param rewardAmount Amount of [**SOLACE**](./SOLACE).
     * @return strikePrice Strike Price in **ETH**.
     */
    function _calculateSolaceEthPrice(uint256 rewardAmount) internal view returns (uint256 strikePrice) {
        uint256 priceX96 = _getPriceX96(_solaceEthPool, _solaceEthTwapInterval); // token1/token0
        // token0/token1 ordering
        if(!_solaceIsToken0) {
            priceX96 = FullMath.mulDiv(FixedPoint96.Q96, FixedPoint96.Q96, priceX96); // eth/solace
        }
        // rewardAmount, swapRate, and priceX96 to strikePrice
        strikePrice = FullMath.mulDiv(rewardAmount * _swapRate / 10000, priceX96, FixedPoint96.Q96);
        return strikePrice;
    }

    /**
     * @notice Calculate the strike price for an amount of [**SOLACE**](./SOLACE).
     * Uses the **ETH**-**USD** uniswap pool.
     * @param rewardAmount Amount of [**SOLACE**](./SOLACE).
     * @return strikePrice Strike Price in **ETH**.
     */
    function _calculateEthUsdPrice(uint256 rewardAmount) internal view returns (uint256 strikePrice) {
        uint256 priceX96 = _getPriceX96(_ethUsdPool, _ethUsdTwapInterval); // token1/token0
        // token0/token1 ordering
        if(!_usdIsToken0) {
            priceX96 = FullMath.mulDiv(FixedPoint96.Q96, FixedPoint96.Q96, priceX96); // eth/usd
        }
        // rewardAmount, priceFloor, and priceX96 to strikePrice
        strikePrice = FullMath.mulDiv(rewardAmount * _priceFloor, priceX96, FixedPoint96.Q96 * 1 ether);
        return strikePrice;
    }

    /**
     * @notice Gets the relative price between tokens in a pool.
     * Can use spot price or twap.
     * @param pool The pool to fetch price.
     * @param twapInterval The interval to calculate twap.
     * @return priceX96 The price as a Q96.
     */
    function _getPriceX96(IUniswapV3Pool pool, uint32 twapInterval) internal view returns (uint256 priceX96) {
        uint160 sqrtPriceX96;
        if (twapInterval == 0) {
            // spot price
            (sqrtPriceX96, , , , , , ) = pool.slot0();
        } else {
            // TWAP
            // retrieve historic tick data from pool
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)
            (int56[] memory tickCumulatives, ) = pool.observe(secondsAgos);
            // math
            int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
            int56 interval = int56(uint56(twapInterval));
            int24 timeWeightedAverageTick = int24(tickCumulativesDelta / interval);
            // always round to negative infinity
            if (tickCumulativesDelta < 0 && (tickCumulativesDelta % interval) != 0) timeWeightedAverageTick--;
            // tick to sqrtPriceX96
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(timeWeightedAverageTick);
        }
        // sqrtPriceX96 to priceX96
        priceX96 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96); // token1/token0
        return priceX96;
    }

    /**
     * @notice Transfers [**SOLACE**](./SOLACE) to the user. It's called by [`exerciseOption()`](#exerciseoption) and [`withdraw()`](#withdraw) functions in the contract.
     * Also adds on their unpaid [**SOLACE**](./SOLACE), and stores new unpaid [**SOLACE**](./SOLACE) if necessary.
     * @param user The user to pay.
     * @param amount The amount to pay _before_ unpaid funds.
     */
    function _transferSolace(address user, uint256 amount) internal {
        // account for unpaid solace
        uint256 unpaidSolace1 = _unpaidSolace[user];
        amount += unpaidSolace1;
        if(amount == 0) return;
        // send eth
        uint256 transferAmount = Math.min(_solace.balanceOf(address(this)), amount);
        uint256 unpaidSolace2 = amount - transferAmount;
        if(unpaidSolace2 != unpaidSolace1) _unpaidSolace[user] = unpaidSolace2;
        SafeERC20.safeTransfer(_solace, user, transferAmount);
    }

    /**
     * @notice Sends this contract's **ETH** balance to `receiver`.
     */
    function _sendValue() internal {
        if(_receiver == address(0x0)) return;
        uint256 amount = address(this).balance;
        if(amount == 0) return;
        // this call may fail. let it
        // funds will be safely stored and can be sent later
        // solhint-disable-next-line avoid-low-level-calls
        _receiver.call{value: amount}(""); // IGNORE THIS WARNING
    }

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     */
    receive () external payable override { }

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     */
    fallback () external payable override { }
}

