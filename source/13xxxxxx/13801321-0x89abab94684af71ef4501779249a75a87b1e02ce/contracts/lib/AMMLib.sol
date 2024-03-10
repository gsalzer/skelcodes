// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../interfaces/IHedge.sol";
import "../interfaces/IOptionVault.sol";
import "./PredyMath.sol";
import "./OptionLib.sol";

/**
 * @title AMMLib
 * @notice The library for option automated market maker
 */
library AMMLib {
    using AMMLib for AMMLib.PoolInfo;
    using AMMLib for AMMLib.Tick;
    using AMMLib for AMMLib.LockedOptionStatePerTick[];
    using PredyMath for uint128;

    /// @dev max uint256
    uint256 constant MAX_UINT256 = 2**256 - 1;

    /// @dev minimum value of tick
    uint32 constant MIN_TICK = 2;

    /// @dev maximum value of tick
    uint32 constant MAX_TICK = 30;

    /// @dev the maximum interval of trading at which the protocol recalculates the premium.
    uint256 constant SAFETY_PERIOD = 6 minutes;

    /**
     * @notice tick is a section of IV
     *   Tick has information about the status of the funds
     * @param supply amount of LP token issued
     * @param balance amount of fund for buying and selling options
     * @param lastSupply last snapshot of supply
     * @param lastBalance last snapshot of balance
     * @param secondsPerLiquidity seconds / liquidity
     * @param reservationForWithdrawal reservation for withdrawal
     * @param hedgePosition current position of the hedge
     */
    struct Tick {
        uint128 supply;
        uint128 balance;
        int128 unrealizedPnL;
        uint128 lastSupply;
        uint128 lastBalance;
        uint128 secondsPerLiquidity;
        uint128 burnReserved;
        uint128 reservationForWithdrawal;
    }

    /**
     * @notice tick state for a option series
     */
    struct LockedOptionStatePerTick {
        // tick id
        uint32 tickId;
        //
        bool isLong;
        // the price per size in last trade recorded per series.
        // scaled by 1e12
        uint128 lastPricePerSize;
        // the timestamp of last trade recorded per series.
        uint128 tradeTime;
    }

    struct Profit {
        // unrealized profit and loss
        int128 unrealizedPnL;
        // cumulative locked premium
        uint128 cumulativeFee;
    }

    /// @dev pool information
    struct PoolInfo {
        address aggregator;
        // option vault contract
        IOptionVault optionVault;
        // collateral address
        address collateral;
        // timestamp of last trade
        uint64 lastBoughtTimestamp;
        // ticks
        mapping(uint32 => Tick) ticks;
        // extra locked amount for each option series
        // tickId => seriesId => buy or sell
        mapping(uint32 => mapping(uint256 => uint128[2])) lockedAmounts;
        // seriesId => LockedOptionState
        mapping(uint256 => LockedOptionStatePerTick[]) locked;
        // expiryId => tickId => Profit
        mapping(uint256 => mapping(uint32 => Profit)) profits;
        // pool configs
        mapping(uint8 => uint128) configs;
    }

    /// @dev buy and sell trade state
    struct TradeState {
        uint32 currentTick;
        uint32 nextTick;
        uint128 stepAmount;
        uint128 remain;
        uint128 currentIV;
        address trader;
        bool isTickLong;
        uint128 pricePerSize;
    }

    /// @dev reservation for withdrawal
    struct Reservation {
        uint128 burn;
        uint128 withdrawableTimestamp;
    }

    uint8 public constant PROTOCOL_FEE_RATIO = 1;
    uint8 public constant MIN_DELTA = 3;
    uint8 public constant BASE_SPREAD = 4;

    /**
     * @notice initialize PoolInfo
     */
    function init(
        PoolInfo storage _pool,
        address _aggregator,
        address _collateral,
        address _optionVault
    ) external {
        require(address(_pool.optionVault) == address(0), "AMMLib: ");

        _pool.collateral = _collateral;
        require(ERC20(_collateral).decimals() == 6);
        _pool.aggregator = _aggregator;
        _pool.optionVault = IOptionVault(_optionVault);

        _pool.configs[PROTOCOL_FEE_RATIO] = 10;
        _pool.configs[MIN_DELTA] = 5 * 1e6;
        // 1 / 500 = 0.2%
        _pool.configs[BASE_SPREAD] = 500;

        IERC20(_pool.collateral).approve(address(_pool.optionVault), MAX_UINT256);
        IERC1155(address(_pool.optionVault)).setApprovalForAll(address(_pool.optionVault), true);
    }

    /**
     * @notice add balance to range
     */
    function addBalance(
        PoolInfo storage _pool,
        uint32 _tickStart,
        uint32 _tickEnd,
        uint128 _mint
    ) external returns (uint128 depositedAmount) {
        require(_mint % (_tickEnd - _tickStart) == 0, "PoolLib: mint is not multiples of range length");
        uint128 mintPerRange = _mint / (_tickEnd - _tickStart);

        for (uint32 i = _tickStart; i < _tickEnd; i++) {
            Tick storage tick = _pool.ticks[i];
            if (tick.supply > 0) {
                // We use roundUp here to make sure that the money going into the contract
                // is always equal or greater than the money going out.
                uint128 a = calSwapAmountForLPToken(tick, mintPerRange, true);

                tick.balance += a;
                depositedAmount += a;
            } else {
                tick.balance += mintPerRange;
                depositedAmount += mintPerRange;
            }
            tick.supply += mintPerRange;
        }
    }

    /**
     * @notice reserve withdrawal
     */
    function reserveWithdrawal(
        PoolInfo storage _pool,
        uint32 _tickStart,
        uint32 _tickEnd,
        uint128 _burn
    ) external {
        require(_burn % (_tickEnd - _tickStart) == 0, "AMMLib: burn is not multiples of range length");
        uint128 burnPerRange = _burn / (_tickEnd - _tickStart);

        for (uint32 i = _tickStart; i < _tickEnd; i++) {
            Tick storage tick = _pool.ticks[i];

            tick.burnReserved += burnPerRange;
        }
    }

    /**
     * @notice remove balance from range
     */
    function removeBalance(
        PoolInfo storage _pool,
        uint32 _tickStart,
        uint32 _tickEnd,
        uint128 _burn
    ) external returns (uint128 withdrawnAmount) {
        require(_burn % (_tickEnd - _tickStart) == 0, "PoolLib: burn is not multiples of range length");
        uint128 burnPerRange = _burn / (_tickEnd - _tickStart);

        for (uint32 i = _tickStart; i < _tickEnd; i++) {
            Tick storage tick = _pool.ticks[i];

            uint128 substraction = removeBalancePerTick(tick, burnPerRange, tick.reservationForWithdrawal);

            withdrawnAmount += substraction;
        }
    }

    /**
     * @notice remove balance from reserved balance
     */
    function removeBalanceFromReservation(
        PoolInfo storage _pool,
        uint32 _tickStart,
        uint32 _tickEnd,
        uint128 _burn
    ) external returns (uint128 withdrawnAmount) {
        require(_burn % (_tickEnd - _tickStart) == 0, "PoolLib: burn is not multiples of range length");
        uint128 burnPerRange = _burn / (_tickEnd - _tickStart);

        for (uint32 i = _tickStart; i < _tickEnd; i++) {
            Tick storage tick = _pool.ticks[i];

            uint128 subWithdrawReserved = calSwapAmountForLPToken(tick, _burn, false);
            uint128 substraction = removeBalancePerTick(tick, burnPerRange, 0);

            // decrease burn reserved
            tick.burnReserved -= burnPerRange;
            if (tick.reservationForWithdrawal > subWithdrawReserved) {
                tick.reservationForWithdrawal -= subWithdrawReserved;
            } else {
                tick.reservationForWithdrawal = 0;
            }

            withdrawnAmount += substraction;
        }
    }

    /**
     * @notice get premium
     * @param _seriesId option id
     * @param _amount amount to buy scaled by 1e8
     * @return premium total premium
     */
    function calculatePremium(
        PoolInfo storage _pool,
        uint256 _seriesId,
        uint128 _amount,
        uint128 _spot,
        bool _isSelling
    ) external view returns (uint128 premium) {
        IOptionVault.OptionSeriesView memory optionSeries = _pool.optionVault.getOptionSeries(_seriesId);

        TradeState memory step = initializeTradeState(_amount, address(0), optionSeries.iv);

        // calculate premium
        premium = _calculatePremium(_pool, step, optionSeries, _spot, _isSelling);
    }

    /**
     * @notice buy options
     * @param _seriesId option id
     * @param _amount amount to buy scaled by 1e8
     * @return premium total premium
     */
    function buy(
        PoolInfo storage _pool,
        uint256 _seriesId,
        uint128 _amount,
        uint128 _spot,
        address _recipient
    ) external returns (uint128 premium) {
        IOptionVault.OptionSeriesView memory optionSeries = _pool.optionVault.getOptionSeries(_seriesId);

        TradeState memory step = initializeTradeState(_amount, _recipient, optionSeries.iv);

        // process buying
        (premium, step) = _buy(_pool, step, optionSeries, _spot);

        // update IV
        setIV(_pool, _seriesId, step.currentIV);

        _pool.lastBoughtTimestamp = uint64(block.timestamp);
    }

    /**
     * @notice sell options
     * @param _seriesId option id
     * @param _amount amount to sell scaled by 1e8
     * @return premium total premium
     */
    function sell(
        PoolInfo storage _pool,
        uint256 _seriesId,
        uint128 _amount,
        uint128 _spot,
        address _seller
    ) external returns (uint128 premium) {
        IOptionVault.OptionSeriesView memory optionSeries = _pool.optionVault.getOptionSeries(_seriesId);

        require(optionSeries.maturity >= 1 days, "AMMLib: maturity must be greater than 1 days");

        TradeState memory step = initializeTradeState(_amount, _seller, optionSeries.iv);

        // process selling
        (premium, step) = _pool._sell(step, optionSeries, _spot);

        // update IV
        _pool.setIV(_seriesId, step.currentIV);

        _pool.lastBoughtTimestamp = uint64(block.timestamp);
    }

    /**
     * @notice settle option serieses of an expiration
     * unlock all collateral in vaults and calculate unrealized profit and loss.
     */
    function settle(PoolInfo storage _pool, uint256 _expiryId) external returns (uint128 totalProtocolFee) {
        IOptionVault.Expiration memory expiration = _pool.optionVault.getExpiration(_expiryId);

        uint32 minTickId = MAX_TICK;
        uint32 maxTickId = MIN_TICK;

        for (uint256 i = 0; i < expiration.seriesIds.length; i++) {
            (uint32 _minTickId, uint32 _maxTickId) = settleInternal(_pool, expiration.seriesIds[i]);

            if (minTickId > _minTickId) {
                minTickId = _minTickId;
            }

            if (maxTickId < _maxTickId) {
                maxTickId = _maxTickId;
            }
        }

        require(minTickId <= maxTickId, "AMMLib: ticks are already settled");

        for (uint32 i = minTickId; i <= maxTickId; i++) {
            Tick storage tick = _pool.ticks[i];

            totalProtocolFee += settleExpiryInternal(_pool, _expiryId, i, tick);

            tick.balance += _pool.optionVault.settleVault(i, _expiryId);

            // update LP token price
            tick.lastBalance = getPoolValueQuote(_pool, tick, i);
            tick.lastSupply = tick.supply;

            // calculate withdrawal reserved amount
            tick.reservationForWithdrawal = PredyMath.mulDiv(
                tick.burnReserved,
                tick.lastBalance,
                tick.lastSupply,
                false
            );
        }
    }

    function settleInternal(PoolInfo storage _pool, uint256 _seriesId)
        internal
        returns (uint32 minTickId, uint32 maxTickId)
    {
        LockedOptionStatePerTick[] memory lockedOptionStates = _pool.locked[_seriesId];

        minTickId = MAX_TICK;
        maxTickId = MIN_TICK;

        for (uint256 i = 0; i < lockedOptionStates.length; i++) {
            uint32 tickId = lockedOptionStates[i].tickId;
            Tick storage tick = _pool.ticks[tickId];

            if (minTickId > tickId) {
                minTickId = tickId;
            }

            if (maxTickId < tickId) {
                maxTickId = tickId;
            }

            if (lockedOptionStates[i].isLong) {
                settleLongPositions(_pool, tick, lockedOptionStates[i], _seriesId);
            }
        }

        delete _pool.locked[_seriesId];
    }

    function settleExpiryInternal(
        PoolInfo storage _pool,
        uint256 _expiryId,
        uint32 _tickId,
        Tick storage _tick
    ) internal returns (uint128) {
        Profit memory profit = _pool.profits[_expiryId][_tickId];

        uint128 cumulativeFee = profit.cumulativeFee;
        // calculate protocol fee
        uint128 protocolFee = cumulativeFee / _pool.configs[PROTOCOL_FEE_RATIO];

        _tick.balance += (cumulativeFee - protocolFee);
        _tick.unrealizedPnL -= profit.unrealizedPnL;

        return protocolFee;
    }

    function settleLongPositions(
        PoolInfo storage _pool,
        Tick storage _tick,
        LockedOptionStatePerTick memory state,
        uint256 _seriesId
    ) internal {
        (, uint128 longSize) = _pool.optionVault.getPositionSize(state.tickId, _seriesId);

        uint128 payout = _pool.optionVault.claim(_seriesId, longSize);

        _tick.balance += payout;
    }

    /**
     * @notice withdraw unrequired collaterals
     */
    function rebalanceCollateral(
        PoolInfo storage _pool,
        uint32 _tickId,
        uint256 _expiryId
    ) external {
        Tick storage tick = _pool.ticks[_tickId];

        uint128 unrequiredCollateralAmount = calculateUnrequiredCollateral(_pool, _tickId, _expiryId);

        if (unrequiredCollateralAmount == 0) {
            return;
        }

        tick.balance += unrequiredCollateralAmount;

        _pool.optionVault.withdraw(_tickId, _expiryId, unrequiredCollateralAmount);
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    function getMintAmount(
        PoolInfo storage _pool,
        uint32 _tickStart,
        uint32 _tickEnd,
        uint128 _amount
    ) external view returns (uint128) {
        uint128 share;
        uint128 range = _tickEnd - _tickStart;
        for (uint32 i = _tickStart; i < _tickEnd; i++) {
            Tick memory tick = _pool.ticks[i];
            if (tick.lastSupply > 0) {
                share += (1e6 * tick.lastBalance) / tick.lastSupply;
            } else {
                share += 1e6;
            }
        }
        return PredyMath.mulDiv(_amount * 1e6, range, share, false);
    }

    function getWithdrawableAmount(
        PoolInfo storage _pool,
        uint32 _tickStart,
        uint32 _tickEnd,
        uint128 _burn
    ) external view returns (uint128 withdrawableAmount) {
        require(_burn % (_tickEnd - _tickStart) == 0, "PoolLib: burn is not multiples of range length");
        uint128 burnPerRange = _burn / (_tickEnd - _tickStart);

        for (uint32 i = _tickStart; i < _tickEnd; i++) {
            Tick memory tick = _pool.ticks[i];
            withdrawableAmount += calSwapAmountForLPToken(tick, burnPerRange, false);
        }
    }

    /**
     * @notice get tick cumulative of seconds per liquidity
     * @param _ticks ticks
     * @param _tickLower lower tick to get seconds per liquidity
     * @param _tickUpper upper tick to get seconds per liquidity
     * @return secondsPerLiquidity scaled by 1e8
     */
    function getSecondsPerLiquidity(
        mapping(uint32 => Tick) storage _ticks,
        uint32 _tickLower,
        uint32 _tickUpper
    ) external view returns (uint128) {
        uint128 secondsPerLiquidity;
        for (uint32 i = _tickLower; i < _tickUpper; i++) {
            Tick memory tick = _ticks[i];
            secondsPerLiquidity += tick.secondsPerLiquidity;
        }
        return secondsPerLiquidity * (_tickUpper - _tickLower);
    }

    ///////////////////////
    // Private Functions //
    ///////////////////////

    /**
     * @notice remove balance from a tick
     */
    function removeBalancePerTick(
        Tick storage _tick,
        uint128 _burn,
        uint128 _reservedAmount
    ) internal returns (uint128) {
        // decrease balance
        uint128 substraction = calSwapAmountForLPToken(_tick, _burn, false);

        require(_tick.balance >= _reservedAmount + substraction, "AMMLib: no enough balance to withdraw");
        _tick.balance -= substraction;

        // decrease supply
        require(_tick.supply >= _burn, "AMMLib: burn is too big");
        _tick.supply -= _burn;

        return substraction;
    }

    function updateSecondsPerLiquidity(PoolInfo storage _pool, uint32 _currentTickId) internal {
        Tick storage state = _pool.ticks[_currentTickId];
        state.updateSecondsPerLiquidity(1e8 * getElapsedTime(_pool.lastBoughtTimestamp));
    }

    /**
     * @notice update seconds per liquidity
     * secondsPerLiquidity is scaled by 1e8
     * @param _tick a tick
     * @param _seconds seconds scaled by 1e8
     */
    function updateSecondsPerLiquidity(Tick storage _tick, uint128 _seconds) internal {
        if (_tick.supply > 0) {
            _tick.secondsPerLiquidity += (1e8 * _seconds) / (_tick.supply);
        }
    }

    /**
     * @notice internal function of calculating premium
     */
    function _calculatePremium(
        PoolInfo storage _pool,
        TradeState memory _step,
        IOptionVault.OptionSeriesView memory _series,
        uint128 _spot,
        bool _isSelling
    ) internal view returns (uint128 totalPremium) {
        while (_step.remain != 0) {
            uint128 premium;
            uint128 fee;
            bool isContinue;

            if (_isSelling) {
                (premium, isContinue) = calculateTradeStateToSell(_pool, _spot, _series, _step);
            } else {
                (premium, fee, isContinue) = calculateTradeStateToBuy(_pool, _spot, _series, _step);
            }

            if (isContinue) {
                continue;
            }

            totalPremium += premium + fee;

            _step.currentTick = _step.nextTick;
        }
        return totalPremium;
    }

    /**
     * @notice process buying options
     * calculate premium and trade state and update ticks
     */
    function _buy(
        PoolInfo storage _pool,
        TradeState memory _step,
        IOptionVault.OptionSeriesView memory _series,
        uint128 _spot
    ) internal returns (uint128 totalPremium, TradeState memory) {
        updateSecondsPerLiquidity(_pool, _step.currentTick);

        while (_step.remain != 0) {
            _step.isTickLong = getIsTickLongFlag(_pool, _series.seriesId, _step.currentTick, false);

            (uint128 premium, uint128 fee, bool isContinue) = calculateTradeStateToBuy(_pool, _spot, _series, _step);
            if (isContinue) {
                continue;
            }
            totalPremium += premium + fee;

            if (_step.isTickLong) {
                // remove long
                removeLongPosition(_pool, _step, _series.expiryId, _series.seriesId, premium, fee);
            } else {
                // add short
                addShortPosition(_pool, _step, _series, premium, fee);
            }

            _step.currentTick = _step.nextTick;
        }
        return (totalPremium, _step);
    }

    /**
     * @notice process buying options for a tick
     * calculate available size of a tick, next IV and premium
     */
    function calculateTradeStateToBuy(
        PoolInfo storage _pool,
        uint128 _spotPrice,
        IOptionVault.OptionSeriesView memory _series,
        TradeState memory _step
    )
        internal
        view
        returns (
            uint128 premium,
            uint128 fee,
            bool
        )
    {
        require(_step.currentTick < MAX_TICK, "AMMLib: tick is too large");

        Tick memory state = _pool.ticks[_step.currentTick];
        uint128 upper = tick2pos(_step.currentTick + 1);

        if (
            state.balance <=
            getUnavailableCollateral(state) + _pool.lockedAmounts[_step.currentTick][_series.seriesId][0] ||
            upper <= _step.currentIV
        ) {
            _step.currentTick += 1;
            return (0, 0, true);
        }
        {
            uint128 lower = tick2pos(_step.currentTick);
            if (_step.currentIV < lower) {
                _step.currentIV = lower;
            }
        }
        uint128 x1;
        {
            // calculate available size
            uint128 available = (state.balance -
                getUnavailableCollateral(state) -
                _pool.lockedAmounts[_step.currentTick][_series.seriesId][0]) / 2;
            uint128 ivMove;
            (available, ivMove) = calAvailableSizeForBuying(
                _pool,
                available,
                _series,
                _step.currentTick,
                upper - _step.currentIV
            );
            if (available >= _step.remain) {
                _step.stepAmount = _step.remain;
                _step.remain = 0;
                _step.nextTick = _step.currentTick;
            } else {
                _step.stepAmount = available;
                // _step.stepAmount must be less than _step.remain
                _step.remain -= _step.stepAmount;
                _step.nextTick = _step.currentTick + 1;
            }

            x1 = _step.currentIV + PredyMath.mulDiv(ivMove, _step.stepAmount, 1e12, true);
        }

        premium = calculatePrice(_pool, _spotPrice, _series, _step.currentIV, x1);
        fee = calculateSpread(_pool, _step.stepAmount, _spotPrice, premium);
        premium = (premium * _step.stepAmount) / 1e10;

        _step.currentIV = x1;
        _step.pricePerSize = (1e12 * (premium + fee)) / _step.stepAmount;

        premium = checkPricePerSize(_pool, _step, _series.seriesId, false, premium + fee) - fee;

        return (premium, fee, false);
    }

    /**
     * @notice sell options
     * trader can only sell to close if the same option series is shorted.
     * @param _pool option id
     * @param _step step information
     * @param _series option
     * @param _spot spot price
     * @return totalPremium total premium
     */
    function _sell(
        PoolInfo storage _pool,
        TradeState memory _step,
        IOptionVault.OptionSeriesView memory _series,
        uint128 _spot
    ) internal returns (uint128 totalPremium, TradeState memory) {
        updateSecondsPerLiquidity(_pool, _step.currentTick);

        while (_step.remain != 0) {
            (uint128 premium, bool isContinue) = calculateTradeStateToSell(_pool, _spot, _series, _step);
            if (isContinue) {
                continue;
            }
            totalPremium += premium;

            if (_step.isTickLong) {
                // add long
                addLongPosition(_pool, _step, _series.expiryId, _series.seriesId, premium);
            } else {
                // remove short
                removeShortPosition(_pool, _step, _series, premium);
            }

            _step.currentTick = _step.nextTick;
        }

        require(_step.remain == 0, "AMMLib: no enough available balance");

        return (totalPremium, _step);
    }

    function calculateTradeStateToSell(
        PoolInfo storage _pool,
        uint128 _spotPrice,
        IOptionVault.OptionSeriesView memory _series,
        TradeState memory _step
    ) internal view returns (uint128 totalPremium, bool) {
        _step.isTickLong = getIsTickLongFlag(_pool, _series.seriesId, _step.currentTick, true);

        Tick memory state = _pool.ticks[_step.currentTick];
        uint128 lower = tick2pos(_step.currentTick);

        if (
            state.balance <=
            getUnavailableCollateral(state) + _pool.lockedAmounts[_step.currentTick][_series.seriesId][1] ||
            _step.currentIV <= lower
        ) {
            require(_step.currentTick > MIN_TICK, "AMMLib: tick is too small");
            _step.currentTick -= 1;
            return (0, true);
        }
        {
            uint128 upper = tick2pos(_step.currentTick + 1);
            if (_step.currentIV > upper) {
                _step.currentIV = upper;
            }
        }

        // calculate start IV and end IV
        uint128 x1 = _step.currentIV;
        {
            (uint128 available, uint128 ivMove) = calAvailableSizeForSelling(
                _pool,
                (state.balance -
                    getUnavailableCollateral(state) -
                    _pool.lockedAmounts[_step.currentTick][_series.seriesId][1]) / 2,
                _spotPrice,
                _series,
                lower,
                _step.currentIV,
                _step.currentTick
            );

            // available must be greater than 0
            if (available >= _step.remain) {
                _step.stepAmount = _step.remain;
                _step.remain = 0;
                _step.nextTick = _step.currentTick;
            } else {
                _step.stepAmount = available;
                // _step.stepAmount must be less than _step.remain
                _step.remain -= _step.stepAmount;
                require(_step.currentTick > MIN_TICK, "AMMLib: tick is too small");
                _step.nextTick = _step.currentTick - 1;
            }

            _step.currentIV -= PredyMath.mulDiv(_step.stepAmount, ivMove, 1e12, true);
        }
        {
            uint128 premium = calculatePrice(_pool, _spotPrice, _series, _step.currentIV, x1);
            premium = premium2c(premium, _step.stepAmount);

            totalPremium += premium;
        }

        _step.pricePerSize = (1e12 * totalPremium) / _step.stepAmount;

        totalPremium = checkPricePerSize(_pool, _step, _series.seriesId, true, totalPremium);

        return (totalPremium, false);
    }

    /**
     * @notice check lastPricePerSize to avoid sandwich attack.
     * compare lastPricePerSize and current pricePerSize, and re-calculate premium if needed.
     */
    function checkPricePerSize(
        PoolInfo storage _pool,
        TradeState memory _step,
        uint256 _seriesId,
        bool _isSelling,
        uint128 _price
    ) internal view returns (uint128 _priceAfter) {
        _priceAfter = _price;

        (LockedOptionStatePerTick memory locked, ) = getLockedOptionStatePerTick(_pool, _seriesId, _step.currentTick);

        if (locked.lastPricePerSize == 0) {
            return _price;
        }

        // premium never re-calculated after SAFETY_PERIOD
        if (locked.tradeTime + SAFETY_PERIOD <= block.timestamp) {
            return _price;
        }

        if (_isSelling) {
            // sell premium must be less than last buy's
            if (_step.pricePerSize > locked.lastPricePerSize) {
                _priceAfter = (locked.lastPricePerSize * _step.stepAmount) / 1e12;
                _step.pricePerSize = locked.lastPricePerSize;
            }
        } else {
            // buy premium must be greater than last sell's
            if (_step.pricePerSize < locked.lastPricePerSize) {
                _priceAfter = (locked.lastPricePerSize * _step.stepAmount) / 1e12;
                _step.pricePerSize = locked.lastPricePerSize;
            }
        }
    }

    /**
     * @notice add long position to pool
     */
    function addLongPosition(
        PoolInfo storage _pool,
        TradeState memory _step,
        uint256 _expiryId,
        uint256 _seriesId,
        uint128 _premium
    ) internal {
        uint32 tickId = _step.currentTick;

        Tick storage tick = _pool.ticks[tickId];

        // deposit USDC to the vault for delta hedge
        uint128 lockAmount = _pool.optionVault.calRequiredMarginForASeries(
            _seriesId,
            -_step.stepAmount.toInt128(),
            IOptionVault.MarginLevel.Safe
        );

        _pool.optionVault.deposit(tickId, _expiryId, lockAmount);

        // decrease premium to pay
        require(tick.balance >= (_premium + lockAmount), "AMMLib: no enough balance");
        tick.balance -= (_premium + lockAmount);

        // add unrealized loss
        int128 premium = _premium.toInt128();

        tick.unrealizedPnL -= premium;
        _pool.profits[_expiryId][tickId].unrealizedPnL -= premium;

        // additional locked amount
        _pool.lockedAmounts[tickId][_seriesId][1] += _premium;

        // add options to the account
        _pool.optionVault.addLong(tickId, _expiryId, _seriesId, _step.stepAmount);

        // add series specific state
        for (uint256 i = 0; i < _pool.locked[_seriesId].length; i++) {
            LockedOptionStatePerTick storage locked = _pool.locked[_seriesId][i];
            if (locked.tickId == tickId) {
                require(locked.isLong);

                // update the last price per size
                locked.tradeTime = uint128(block.timestamp);
                locked.lastPricePerSize = _step.pricePerSize;
                return;
            }
        }

        // if there is no state, add new
        _pool.locked[_seriesId].push(
            LockedOptionStatePerTick(tickId, true, _step.pricePerSize, uint128(block.timestamp))
        );
    }

    /**
     * @notice remove long position from pool
     */
    function removeLongPosition(
        PoolInfo storage _pool,
        TradeState memory _step,
        uint256 _expiryId,
        uint256 _seriesId,
        uint128 _premium,
        uint128 _fee
    ) internal {
        uint32 tickId = _step.currentTick;

        Tick storage tick = _pool.ticks[tickId];

        // add received premium to balance
        tick.balance += _premium;

        // add unrealized profit from premium
        int128 premium = _premium.toInt128();

        tick.unrealizedPnL += premium;

        _pool.profits[_expiryId][tickId].unrealizedPnL += premium;
        _pool.profits[_expiryId][tickId].cumulativeFee += _fee;

        // remove options from the account
        _pool.optionVault.removeLong(tickId, _expiryId, _seriesId, _step.stepAmount);

        // calculate unrequired collateral and withdraw the collateral
        uint128 unrequiredCollateral = _pool.optionVault.closeShortPosition(tickId, _seriesId, 0, 1e6);

        tick.balance += unrequiredCollateral;

        // decrease additional locked premium
        if (_pool.lockedAmounts[tickId][_seriesId][1] > _premium) {
            _pool.lockedAmounts[tickId][_seriesId][1] -= _premium;
        } else {
            _pool.lockedAmounts[tickId][_seriesId][1] = 0;
        }

        // transfer options to the trader
        ERC1155(address(_pool.optionVault)).safeTransferFrom(
            address(this),
            _step.trader,
            _seriesId,
            _step.stepAmount,
            ""
        );

        // update series specific state
        for (uint256 i = 0; i < _pool.locked[_seriesId].length; i++) {
            LockedOptionStatePerTick storage locked = _pool.locked[_seriesId][i];
            if (locked.tickId == tickId) {
                require(locked.isLong);

                // update the last price per size
                locked.tradeTime = uint128(block.timestamp);
                locked.lastPricePerSize = _step.pricePerSize;
                return;
            }
        }

        // if there is no series state, revert
        revert("AMMLib: series state not found");
    }

    /**
     * @notice add short position to pool
     */
    function addShortPosition(
        PoolInfo storage _pool,
        TradeState memory _step,
        IOptionVault.OptionSeriesView memory _series,
        uint128 _premium,
        uint128 _fee
    ) internal {
        uint32 tickId = _step.currentTick;

        // deposit 100% of IM collateral and premium, and write options(transfer options to the trader)
        uint128 lockAmount = _pool.optionVault.depositAndWrite(
            tickId,
            _series.seriesId,
            1e6,
            _step.stepAmount,
            _step.trader
        );

        require(lockAmount >= _premium, "AMMLib: lockAmount must be greater than premium");

        Tick storage tick = _pool.ticks[tickId];

        // decrease lockAmount from pool balance
        require(tick.balance >= lockAmount + getUnavailableCollateral(tick), "AMMLib: enough balance to lock");
        tick.balance -= lockAmount - _premium;

        // add unrealized profit from premium
        int128 premium = _premium.toInt128();

        tick.unrealizedPnL += premium;

        _pool.profits[_series.expiryId][tickId].unrealizedPnL += premium;
        _pool.profits[_series.expiryId][tickId].cumulativeFee += _fee;

        // calculate additional lock amount
        _pool.lockedAmounts[tickId][_series.seriesId][0] += lockAmount;

        // update series specific state(premium and fee)
        for (uint256 i = 0; i < _pool.locked[_series.seriesId].length; i++) {
            LockedOptionStatePerTick storage locked = _pool.locked[_series.seriesId][i];
            if (locked.tickId == tickId) {
                require(!locked.isLong);

                // update the last price per size
                locked.tradeTime = uint128(block.timestamp);
                locked.lastPricePerSize = _step.pricePerSize;
                return;
            }
        }

        // if there is no series state, create new
        _pool.locked[_series.seriesId].push(
            LockedOptionStatePerTick(tickId, false, _step.pricePerSize, uint128(block.timestamp))
        );
    }

    /**
     * @notice remove short position from pool
     */
    function removeShortPosition(
        PoolInfo storage _pool,
        TradeState memory _step,
        IOptionVault.OptionSeriesView memory _series,
        uint128 _premium
    ) internal {
        uint32 tickId = _step.currentTick;

        // burn options from the account
        // calculate unrequired collateral and withdraw the collateral
        uint128 unrequiredCollateral = _pool.optionVault.closeShortPosition(
            tickId,
            _series.seriesId,
            _step.stepAmount,
            1e6
        );

        Tick storage tick = _pool.ticks[tickId];

        uint128 balance = tick.balance;

        // increase withdrawn collateral to balance
        balance += unrequiredCollateral;

        // decrease premium to pay
        balance -= _premium;

        tick.balance = balance;

        // add unrealized loss
        int128 premium = _premium.toInt128();

        tick.unrealizedPnL -= premium;

        _pool.profits[_series.expiryId][tickId].unrealizedPnL -= premium;

        // additional locked amount
        if (_pool.lockedAmounts[tickId][_series.seriesId][0] > unrequiredCollateral) {
            _pool.lockedAmounts[tickId][_series.seriesId][0] -= unrequiredCollateral;
        } else {
            _pool.lockedAmounts[tickId][_series.seriesId][0] = 0;
        }

        // update series specific state
        for (uint256 i = 0; i < _pool.locked[_series.seriesId].length; i++) {
            LockedOptionStatePerTick storage locked = _pool.locked[_series.seriesId][i];
            if (locked.tickId == tickId) {
                require(!locked.isLong);

                // update the last price per size
                locked.tradeTime = uint128(block.timestamp);
                locked.lastPricePerSize = _step.pricePerSize;
                return;
            }
        }

        // if there is no series state, revert
        revert("AMMLib: series state not found");
    }

    function calculateUnrequiredCollateral(
        PoolInfo storage _pool,
        uint32 _tickId,
        uint256 _expiryId
    ) internal view returns (uint128 amount) {
        uint128 accountCollateral = _pool.optionVault.getVault(_tickId, _expiryId).collateral;

        uint128 requiredCollateral = getSafeMargin(_pool, _tickId, _expiryId);

        if (requiredCollateral < accountCollateral) {
            return accountCollateral - requiredCollateral;
        }

        return 0;
    }

    /**
     * @notice get pool value quote
     * returns the sum of pool value and hedged value
     */
    function getPoolValueQuote(
        PoolInfo storage _pool,
        Tick memory _tick,
        uint32 _tickId
    ) internal view returns (uint128 total) {
        uint128 b = _tick.balance + _pool.optionVault.getCollateralValueQuote(_tickId);

        if (_tick.unrealizedPnL > 0) {
            return b - uint128(_tick.unrealizedPnL);
        } else {
            return b + uint128(-_tick.unrealizedPnL);
        }
    }

    function calSwapAmountForLPToken(
        Tick memory _tick,
        uint128 _amount,
        bool _isDeposit
    ) internal pure returns (uint128) {
        if (_tick.lastBalance == 0 || _tick.lastSupply == 0) {
            return _amount;
        } else {
            return PredyMath.mulDiv(_amount, _tick.lastBalance, _tick.lastSupply, _isDeposit);
        }
    }

    function calculatePrice(
        PoolInfo storage _pool,
        uint128 _spot,
        IOptionVault.OptionSeriesView memory _series,
        uint128 _x0,
        uint128 _x1
    ) internal view returns (uint128) {
        uint256 p = PriceCalculator.calculatePrice2(
            _spot,
            _series.strike,
            _series.maturity,
            _x0,
            _x1,
            _series.isPut,
            _pool.configs[MIN_DELTA]
        );
        return uint128(p);
    }

    /**
     * @notice calculating spread of premium.
     * spread is 0.4% of size and 1% of premium
     * @param _amount option size scaled by 1e8
     * @param _spot oracle price scaled by 1e8
     * @param _premium premium scaled by 1e8
     * @return fee scaled by 1e6
     */
    function calculateSpread(
        PoolInfo storage _pool,
        uint128 _amount,
        uint128 _spot,
        uint128 _premium
    ) internal view returns (uint128) {
        return (_amount * (_spot / _pool.configs[BASE_SPREAD] + _premium / 100)) / (1e10);
    }

    /**
     * @notice initialize trade state
     */
    function initializeTradeState(
        uint128 _amount,
        address _trader,
        uint64 _iv
    ) internal pure returns (TradeState memory) {
        uint128 currentIV = _iv;
        uint32 tick = uint32(currentIV / 1e7);

        return TradeState(tick, tick, 0, _amount, currentIV, _trader, false, 0);
    }

    function getIsTickLongFlag(
        PoolInfo storage _pool,
        uint256 _seriesId,
        uint32 _tickId,
        bool _isSelling
    ) internal view returns (bool) {
        (LockedOptionStatePerTick memory locked, bool exists) = getLockedOptionStatePerTick(_pool, _seriesId, _tickId);
        return exists ? locked.isLong : _isSelling;
    }

    /**
     * @notice calculate available size for buying
     * if tick is long, available size is same as the size of tick's long position.
     * if tick is short, available size is (balance / collateral to lock).
     * @return (available size, ivMove)
     *  available size is the size that trader can buy
     *  ivMove is iv changes per size in this trade
     */
    function calAvailableSizeForBuying(
        PoolInfo storage _pool,
        uint128 _c,
        IOptionVault.OptionSeriesView memory _series,
        uint32 _tickId,
        uint128 _ivRange
    ) internal view returns (uint128, uint128) {
        (LockedOptionStatePerTick memory locked, bool exists) = getLockedOptionStatePerTick(
            _pool,
            _series.seriesId,
            _tickId
        );

        if (exists && locked.isLong) {
            // get pool's long position size
            (, uint128 longSize) = _pool.optionVault.getPositionSize(_tickId, _series.seriesId);

            return (longSize, (1e12 * _ivRange) / longSize);
        } else {
            uint128 safeMargin = _pool.optionVault.calRequiredMarginForASeries(
                _series.seriesId,
                1e8,
                IOptionVault.MarginLevel.Safe
            );
            uint128 availableSize = (1e8 * _c) / safeMargin;

            // ivMove is scaled by 1e12
            uint128 ivMove = (1e12 * _ivRange) / availableSize;

            return (availableSize, ivMove);
        }
    }

    /**
     * @notice calculate available size for selling
     * if tick is long, available size is (balance / (premium to pay + collateral to lock)).
     * if tick is short, available size is same as the size of tick's short position.
     * @return (available size, ivMove)
     *  available size is the size that trader can sell
     *  ivMove is iv changes per size in this trade
     */
    function calAvailableSizeForSelling(
        PoolInfo storage _pool,
        uint128 _c,
        uint128 _spot,
        IOptionVault.OptionSeriesView memory _series,
        uint128 _iv0,
        uint128 _iv1,
        uint32 _tickId
    ) internal view returns (uint128, uint128) {
        (LockedOptionStatePerTick memory locked, bool exists) = getLockedOptionStatePerTick(
            _pool,
            _series.seriesId,
            _tickId
        );

        uint128 ivRange = 1e12 * (_iv1 - _iv0);

        if (!exists || locked.isLong) {
            // pricePerAmount is estimation price when IV moves from lower to _step.position (price/amount)
            uint128 availableSize;
            {
                uint128 pricePerAmount = calculatePrice(_pool, _spot, _series, _iv0, _iv1);
                uint128 safeMargin = _pool.optionVault.calRequiredMarginForASeries(
                    _series.seriesId,
                    -1e8,
                    IOptionVault.MarginLevel.Safe
                );

                availableSize = (_c * 1e10) / (pricePerAmount + 1e2 * safeMargin);
            }

            uint128 ivMove = ivRange / availableSize;

            return (availableSize, ivMove);
        } else {
            // get pool's short position size
            uint128 availableSize = getVaultSize(_pool, _tickId, _series.seriesId);
            return (availableSize, ivRange / availableSize);
        }
    }

    function getVaultSize(
        PoolInfo storage _pool,
        uint32 _tickId,
        uint256 _seriesId
    ) internal view returns (uint128) {
        (uint128 shortSize, ) = _pool.optionVault.getPositionSize(_tickId, _seriesId);
        return shortSize;
    }

    function getUnavailableCollateral(Tick memory _tick) internal pure returns (uint128) {
        return _tick.reservationForWithdrawal;
    }

    /**
     * @notice convert premium to amount of collateral
     * @param _premium premium
     * @param _size size of option
     */
    function premium2c(uint128 _premium, uint128 _size) internal pure returns (uint128) {
        uint128 r = (_premium * _size) / 1e8;
        return r / 1e2;
    }

    function getLockedOptionStatePerTick(
        PoolInfo storage _pool,
        uint256 _seriesId,
        uint32 _tickId
    ) internal view returns (LockedOptionStatePerTick memory, bool exists) {
        for (uint256 i = 0; i < _pool.locked[_seriesId].length; i++) {
            if (_pool.locked[_seriesId][i].tickId == _tickId) {
                return (_pool.locked[_seriesId][i], true);
            }
        }

        return (LockedOptionStatePerTick(0, false, 0, 0), false);
    }

    /**
     * @notice set pool IV
     */
    function setIV(
        PoolInfo storage _poolInfo,
        uint256 _seriesId,
        uint128 _iv
    ) internal {
        _poolInfo.optionVault.setIV(_seriesId, _iv);
    }

    /**
     * @notice get elapsed time from latest bought
     */
    function getElapsedTime(uint128 _lastBoughtTimestamp) internal view returns (uint128) {
        return uint128(block.timestamp) - _lastBoughtTimestamp;
    }

    /**
     * @notice calculate safe collateral
     */
    function getSafeMargin(
        PoolInfo storage _pool,
        uint32 _tickId,
        uint256 _expiryId
    ) internal view returns (uint128) {
        return _pool.optionVault.getRequiredMargin(_tickId, _expiryId, IOptionVault.MarginLevel.Safe);
    }

    function validateTick(uint32 _tickId) public pure {
        require(MIN_TICK <= _tickId, "AMM: start must be greater than MIN");
        require(_tickId < MAX_TICK, "AMM: tick must be less than MAX");
    }

    function validateRange(uint32 _s, uint32 _e) external pure {
        require(MIN_TICK <= _s, "AMM: start must be greater than MIN");
        require(_s < _e, "AMM: end must be greater than start");
        require(_s < MAX_TICK && _e <= MAX_TICK, "AMM: tick must be less than MAX");
        require(_s > 0 && _e > 1, "AMM: tick must be greater than 1");
    }

    function tick2pos(uint32 _tick) internal pure returns (uint128) {
        if (_tick >= MAX_TICK) {
            return 1e7 * 50;
        } else {
            return 1e7 * _tick;
        }
    }
}

