// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "./IPCVDeposit.sol";
import "../refs/UniRef.sol";

/// @title abstract implementation for Uniswap LP PCV Deposit
/// @author Ring Protocol
abstract contract UniswapPCVDeposit is IPCVDeposit, UniRef {
    using Decimal for Decimal.D256;
    using SafeCast for uint256;

    uint24 public override fee = 500;
    int24 public override tickLower;
    int24 public override tickUpper;

    /// @notice Uniswap PCV Deposit constructor
    /// @param _core Ring Core for reference
    /// @param _pool Uniswap Pair to deposit to
    /// @param _nft Uniswap V3 position manager to reference
    /// @param _router Uniswap Router
    /// @param _oracle oracle for reference
    constructor(
        address _core,
        address _pool,
        address _nft,
        address _router,
        address _oracle
    ) UniRef(_core, _pool, _nft, _router, _oracle) {}

    /// @notice withdraw tokens from the PCV allocation
    /// @param amountLiquidity withdrawn
    /// @param to the address to send PCV to
    function withdraw(address to, uint256 amountLiquidity)
        external
        override
        onlyPCVController
        whenNotPaused
    {
        require(
            amountLiquidity <= liquidityOwned(),
            "UniswapPCVDeposit: Insufficient underlying"
        );

        _removeLiquidity(amountLiquidity.toUint128());

        _transferWithdrawn(to);

        _burnRusdHeld();

        emit Withdrawal(msg.sender, to, amountLiquidity);
    }

    /// @notice burn old position and reset parameters of new position
    /// @param _fee of new position
    /// @param _tickLower of new position
    /// @param _tickUpper of new position
    function burnAndReset(uint24 _fee, int24 _tickLower, int24 _tickUpper)
        external
        override
        onlyPCVController
        whenNotPaused
    {
        nft.burn(tokenId);
        tokenId = 0;
        fee = _fee;
        tickLower = _tickLower;
        tickUpper = _tickUpper;
    }

    /// @notice returns total value of PCV in the Deposit
    function totalLiquidity() public view override returns (uint128) {
        return liquidityOwned();
    }

    function _getAmountRusdToDeposit(uint256 amountToken)
        internal
        view
        returns (uint256 amountRusd)
    {
        return peg().mul(amountToken).asUint256();
    }

    function _removeLiquidity(uint128 liquidity) internal virtual;

    function _transferWithdrawn(address to) internal virtual;
}

