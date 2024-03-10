// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/libraries/SafeCast.sol";
import "./IUniswapPCVController.sol";
import "../refs/UniRef.sol";
import "../utils/Timed.sol";
import "../utils/Roots.sol";

/// @title a IUniswapPCVController implementation for ERC20
/// @author Ring Protocol
contract ERC20UniswapPCVController is IUniswapPCVController, UniRef, Timed {
    using Decimal for Decimal.D256;
    using SafeMathCopy for uint128;
    using SafeMathCopy for uint256;
    using SafeCast for uint256;
    using Roots for uint256;

    uint256 public override reweightWithdrawBPs = 9900;

    uint256 internal _reweightDuration = 4 hours;

    uint256 internal constant BASIS_POINTS_GRANULARITY = 10000;

    uint24 public override fee = 500;

    /// @notice returns the linked pcv deposit contract
    IPCVDeposit public override pcvDeposit;

    /// @notice gets the RUSD reward incentive for reweighting
    uint256 public override reweightIncentiveAmount;

    Decimal.D256 internal _minDistanceForReweight;

    /// @notice ERC20UniswapPCVController constructor
    /// @param _core Ring Core for reference
    /// @param _pcvDeposit PCV Deposit to reweight
    /// @param _oracle oracle for reference
    /// @param _incentiveAmount amount of RUSD for triggering a reweight
    /// @param _minDistanceForReweightBPs minimum distance from peg to reweight in basis points
    /// @param _pool Uniswap V3 pool contract to reweight
    /// @param _nft Uniswap V3 position manager to reference
    /// @param _router Uniswap Router
    constructor(
        address _core,
        address _pcvDeposit,
        address _oracle,
        uint256 _incentiveAmount,
        uint256 _minDistanceForReweightBPs,
        address _pool,
        address _nft,
        address _router
    ) UniRef(_core, _pool, _nft, _router, _oracle) Timed(_reweightDuration) {
        pcvDeposit = IPCVDeposit(_pcvDeposit);

        reweightIncentiveAmount = _incentiveAmount;
        _minDistanceForReweight = Decimal.ratio(
            _minDistanceForReweightBPs,
            BASIS_POINTS_GRANULARITY
        );

        // start timer
        _initTimed();
    }

    /// @notice reweights the linked PCV Deposit to the peg price. Needs to be reweight eligible
    function reweight() external override whenNotPaused {
        require(
            reweightEligible(),
            "ERC20UniswapPCVController: Not passed reweight time or not at min distance"
        );
        _reweight();
        _incentivize();
    }

    /// @notice reinvest the fee income into the linked PCV Deposit.
    function reinvest() external override whenNotPaused {
        pcvDeposit.collect();
        pcvDeposit.deposit();

        emit Reinvest(msg.sender);
    }

    /// @notice reweights regardless of eligibility
    function forceReweight() external override onlyGuardianOrGovernor {
        _reweight();
    }

    /// @notice sets the target PCV Deposit address
    function setPCVDeposit(address _pcvDeposit) external override onlyGovernor {
        pcvDeposit = IPCVDeposit(_pcvDeposit);
        emit PCVDepositUpdate(_pcvDeposit);
    }

    /// @notice sets the target PCV Deposit parameters
    function setPCVDepositParameters(uint24 _fee, int24 _tickLower, int24 _tickUpper) external override onlyGovernor {
        pcvDeposit.withdraw(address(pcvDeposit), pcvDeposit.totalLiquidity());
        pcvDeposit.burnAndReset(_fee, _tickLower, _tickUpper);
        pcvDeposit.deposit();

        emit PCVDepositParametersUpdate(address(pcvDeposit), fee, _tickLower, _tickUpper);
    }

    /// @notice sets the reweight incentive amount
    function setReweightIncentive(uint256 amount)
        external
        override
        onlyGovernor
    {
        reweightIncentiveAmount = amount;
        emit ReweightIncentiveUpdate(amount);
    }

    /// @notice sets the reweight withdrawal BPs
    function setReweightWithdrawBPs(uint256 _reweightWithdrawBPs)
        external
        override
        onlyGovernor
    {
        require(_reweightWithdrawBPs <= BASIS_POINTS_GRANULARITY, "ERC20UniswapPCVController: withdraw percent too high");
        reweightWithdrawBPs = _reweightWithdrawBPs;
        emit ReweightWithdrawBPsUpdate(_reweightWithdrawBPs);
    }

    /// @notice sets the reweight min distance in basis points
    function setReweightMinDistance(uint256 basisPoints)
        external
        override
        onlyGovernor
    {
        _minDistanceForReweight = Decimal.ratio(
            basisPoints,
            BASIS_POINTS_GRANULARITY
        );
        emit ReweightMinDistanceUpdate(basisPoints);
    }

    /// @notice sets the reweight duration
    function setDuration(uint256 _duration)
        external
        override
        onlyGovernor
    {
       _setDuration(_duration);
    }

    /// @notice sets the fee
    function setFee(uint24 _fee) external override onlyGovernor {
        fee = _fee;
        emit SwapFeeUpdate(_fee);
    }

    /// @notice signal whether the reweight is available. Must have incentive parity and minimum distance from peg
    function reweightEligible() public view override returns (bool) {
        bool magnitude =
            _getDistanceToPeg().greaterThan(_minDistanceForReweight);
        // incentive parity is achieved after a certain time relative to distance from peg
        bool time = isTimeEnded();
        return magnitude && time;
    }

    /// @notice minimum distance as a percentage from the peg for a reweight to be eligible
    function minDistanceForReweight()
        external
        view
        override
        returns (Decimal.D256 memory)
    {
        return _minDistanceForReweight;
    }

    function _incentivize() internal ifMinterSelf {
        rusd().mint(msg.sender, reweightIncentiveAmount);
    }

    function _reweight() internal {
        _withdraw();
        _returnToPeg();

        // resupply PCV at peg ratio
        uint256 balance = IERC20(token()).balanceOf(address(this));
        // transfer the entire pcv erc20 token balance to pcvDeposit, then run deposit
        TransferHelper.safeTransfer(token(), address(pcvDeposit), balance);
        pcvDeposit.deposit();

        _burnRusdHeld();

        // reset timer
        _initTimed();

        emit Reweight(msg.sender);
    }

    function _returnToPeg() internal {
        Decimal.D256 memory _peg = peg();
        require(
            _isBelowPeg(_peg),
            "ERC20UniswapPCVController: already at or above peg"
        );

        _swapErc20();
    }


    function _swapErc20() internal {
        uint256 balance = IERC20(token()).balanceOf(address(this));

        if (balance != 0) {
            uint256 endOfTime = uint256(-1);
            address _token = token();
            address _rusd = address(rusd());
            Decimal.D256 memory _peg = (_token < _rusd) ? peg() : invert(peg());
            uint160 priceLimit = _peg.mul(2**96).asUint256().mul(2**96).sqrt().toUint160();
            router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _token,
                    tokenOut: _rusd,
                    fee: fee,
                    recipient: address(this),
                    deadline: endOfTime,
                    amountIn: balance,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: priceLimit
                })
            );
        }
    }

    function _withdraw() internal {
        // Only withdraw a portion to prevent rounding errors on Uni LP dust
        uint256 value =
            pcvDeposit.totalLiquidity().mul(reweightWithdrawBPs) /
                BASIS_POINTS_GRANULARITY;
        require(value > 0, "ERC20UniswapPCVController: No liquidity to withdraw");
        pcvDeposit.withdraw(address(this), value);
    }
}

