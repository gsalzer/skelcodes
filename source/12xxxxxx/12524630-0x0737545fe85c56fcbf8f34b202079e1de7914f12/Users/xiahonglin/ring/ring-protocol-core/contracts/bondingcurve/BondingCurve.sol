// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./IBondingCurve.sol";
import "../refs/OracleRef.sol";
import "../pcv/PCVSplitter.sol";
import "../utils/Timed.sol";

/// @title an abstract bonding curve for purchasing RUSD
/// @author Ring Protocol
abstract contract BondingCurve is IBondingCurve, OracleRef, PCVSplitter, Timed {
    using Decimal for Decimal.D256;
    using SafeMathCopy for uint256;

    /// @notice the total amount of RUSD purchased on bonding curve. RUSD_b from the whitepaper
    uint256 public override totalPurchased; // RUSD_b for this curve

    /// @notice the buffer applied on top of the peg purchase price
    uint256 public override buffer = 50;
    uint256 public constant BUFFER_GRANULARITY = 10_000;

    /// @notice amount of RUSD paid for allocation when incentivized
    uint256 public override incentiveAmount;

    /// @notice constructor
    /// @param _core Ring Core to reference
    /// @param _pcvDeposits the PCV Deposits for the PCVSplitter
    /// @param _ratios the ratios for the PCVSplitter
    /// @param _oracle the UniswapOracle to reference
    /// @param _duration the duration between incentivizing allocations
    /// @param _incentive the amount rewarded to the caller of an allocation
    constructor(
        address _core,
        address[] memory _pcvDeposits,
        uint256[] memory _ratios,
        address _oracle,
        uint256 _duration,
        uint256 _incentive
    )
        OracleRef(_core, _oracle)
        PCVSplitter(_pcvDeposits, _ratios)
        Timed(_duration)
    {
        incentiveAmount = _incentive;

        _initTimed();
    }

    /// @notice sets the bonding curve price buffer
    function setBuffer(uint256 _buffer) external override onlyGovernor {
        require(
            _buffer < BUFFER_GRANULARITY,
            "BondingCurve: Buffer exceeds or matches granularity"
        );
        buffer = _buffer;
        emit BufferUpdate(_buffer);
    }

    /// @notice sets the allocate incentive amount
    function setIncentiveAmount(uint256 _incentiveAmount) external override onlyGovernor {
        incentiveAmount = _incentiveAmount;
        emit IncentiveAmountUpdate(_incentiveAmount);
    }

    /// @notice sets the allocate incentive frequency
    function setIncentiveFrequency(uint256 _frequency) external override onlyGovernor {
        _setDuration(_frequency);
    }

    /// @notice sets the allocation of incoming PCV
    function setAllocation(
        address[] calldata allocations,
        uint256[] calldata ratios
    ) external override onlyGovernor {
        _setAllocation(allocations, ratios);
    }

    /// @notice batch allocate held PCV
    function allocate() external override whenNotPaused {
        require((!Address.isContract(msg.sender)), "BondingCurve: Caller is a contract");
        uint256 amount = getTotalPCVHeld();
        require(amount != 0, "BondingCurve: No PCV held");

        _allocate(amount);
        _incentivize();

        emit Allocate(msg.sender, amount);
    }

    /// @notice return current instantaneous bonding curve price
    /// @return price reported as RUSD per X with X being the underlying asset
    function getCurrentPrice()
        external
        view
        override
        returns (Decimal.D256 memory)
    {
        return peg().mul(_getBufferMultiplier());
    }

    /// @notice return amount of RUSD received after a bonding curve purchase
    /// @param amountIn the amount of underlying used to purchase
    /// @return amountOut the amount of RUSD received
    function getAmountOut(uint256 amountIn)
        public
        view
        override
        returns (uint256 amountOut)
    {
        uint256 adjustedAmount = _getAdjustedAmount(amountIn);
        amountOut = _getBufferAdjustedAmount(adjustedAmount);
        return amountOut;
    }

    /// @notice return the average price of a transaction along bonding curve
    /// @param amountIn the amount of underlying used to purchase
    /// @return price reported as USD per RUSD
    function getAverageUSDPrice(uint256 amountIn)
        external
        view
        override
        returns (Decimal.D256 memory)
    {
        uint256 adjustedAmount = _getAdjustedAmount(amountIn);
        uint256 amountOut = getAmountOut(amountIn);
        return Decimal.ratio(adjustedAmount, amountOut);
    }

    /// @notice the amount of PCV held in contract and ready to be allocated
    function getTotalPCVHeld() public view virtual override returns (uint256);

    /// @notice multiplies amount in by the peg to convert to RUSD
    function _getAdjustedAmount(uint256 amountIn)
        internal
        view
        returns (uint256)
    {
        return peg().mul(amountIn).asUint256();
    }

    /// @notice mint RUSD and send to buyer destination
    function _purchase(uint256 amountIn, address to)
        internal
        returns (uint256 amountOut)
    {
        amountOut = getAmountOut(amountIn);
        _incrementTotalPurchased(amountOut);
        rusd().mint(to, amountOut);

        emit Purchase(to, amountIn, amountOut);

        return amountOut;
    }

    function _incrementTotalPurchased(uint256 amount) internal {
        totalPurchased = totalPurchased.add(amount);
    }

    /// @notice if window has passed, reward caller and reset window
    function _incentivize() internal virtual {
        if (isTimeEnded()) {
            _initTimed(); // reset window
            rusd().mint(msg.sender, incentiveAmount);
        }
    }

    /// @notice returns the buffer on the bonding curve price
    function _getBufferMultiplier() internal view returns (Decimal.D256 memory) {
        uint256 granularity = BUFFER_GRANULARITY;
        // uses granularity - buffer (i.e. 1-b) instead of 1+b because the peg is inverted
        return Decimal.ratio(granularity - buffer, granularity);
    }

    function _getBufferAdjustedAmount(uint256 amountIn)
        internal
        view
        returns (uint256)
    {
        return _getBufferMultiplier().mul(amountIn).asUint256();
    }
}

