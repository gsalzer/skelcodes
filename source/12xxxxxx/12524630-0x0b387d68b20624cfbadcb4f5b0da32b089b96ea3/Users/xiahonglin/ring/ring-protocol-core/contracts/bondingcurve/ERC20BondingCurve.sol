// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./BondingCurve.sol";
import "../pcv/IPCVDeposit.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

/// @title a square root growth bonding curve for purchasing RUSD with ETH
/// @author Ring Protocol
contract ERC20BondingCurve is BondingCurve {
    address public immutable tokenAddress;

    constructor(
        address core,
        address[] memory pcvDeposits,
        uint256[] memory ratios,
        address oracle,
        uint256 duration,
        uint256 incentive,
        address _tokenAddress
    )
        BondingCurve(
            core,
            pcvDeposits,
            ratios,
            oracle,
            duration,
            incentive
        )
    {
        tokenAddress = _tokenAddress;
    }

    /// @notice purchase RUSD for underlying tokens
    /// @param to address to receive RUSD
    /// @param amountIn amount of underlying tokens input
    /// @return amountOut amount of RUSD received
    function purchase(address to, uint256 amountIn)
        external
        payable
        virtual
        override
        whenNotPaused
        returns (uint256 amountOut)
    {
        // safeTransferFrom(address token, address from, address to, uint value)
        TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), amountIn);
        return _purchase(amountIn, to);
    }

    function getTotalPCVHeld() public view virtual override returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function _allocateSingle(uint256 amount, address pcvDeposit)
        internal
        virtual
        override
    {
        // safeTransfer(address token, address to, uint value)
        TransferHelper.safeTransfer(tokenAddress, pcvDeposit, amount);
        IPCVDeposit(pcvDeposit).deposit();
    }
}

