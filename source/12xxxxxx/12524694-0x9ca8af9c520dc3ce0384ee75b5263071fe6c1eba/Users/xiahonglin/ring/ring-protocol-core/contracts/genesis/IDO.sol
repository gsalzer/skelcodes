// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./IDOInterface.sol";
import "../refs/UniRef.sol";

/// @title an initial DeFi offering for the RING token
/// @author Ring Protocol
contract IDO is IDOInterface, UniRef {
    using SafeMathCopy for uint256;

    /// @notice IDO constructor
    /// @param _core Ring Core address to reference
    /// @param _pool the Uniswap V3 pool contract of the IDO
    /// @param _nft Uniswap V3 position manager to reference
    /// @param _router the Uniswap router contract
    constructor(
        address _core,
        address _pool,
        address _nft,
        address _router
    )
        UniRef(_core, _pool, _nft, _router, address(0)) // no oracle needed
    {}

    /// @notice deploys all held RING on Uniswap at the given ratio
    /// @dev the contract will mint any RUSD necessary to do the listing. Assumes no existing LP
    function deploy()
        external
        override
        onlyGenesisGroup
    {
        uint256 ringAmount = ringBalance();

        // calculate and mint amount of RUSD for IDO
        uint256 rusdAmount = ringAmount.div(20); // 500K RUSD
        _mintRusd(rusdAmount);

        // deposit liquidity
        uint256 endOfTime = uint256(-1);
        address rusdAddress = address(rusd());
        address ringAddress = address(ring());
        (address token0, address token1) = rusdAddress < ringAddress ? (rusdAddress, ringAddress) : (ringAddress, rusdAddress);
        (uint256 amount0Desired, uint256 amount1Desired) = rusdAddress < ringAddress ? (rusdAmount, ringAmount) : (ringAmount, rusdAmount);
        (tokenId, , ,) = nft.mint(
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                tickLower: -887220,
                tickUpper: 887220,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: endOfTime,
                fee: 3000
            })
        );

        emit Deploy(rusdAmount, ringAmount);
    }

    /// @notice collect override to governor of timelock
    function collect(address to) public override onlyGovernor {
        nft.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: to,
                amount0Max: uint128(-1),
                amount1Max: uint128(-1)
            })
        );
        rusd().transfer(to, rusd().balanceOf(address(this)));
        ring().transfer(to, ring().balanceOf(address(this)));
    }

    /// @notice unlock override to governor of timelock
    function unlockLiquidity(address to) external override onlyGovernor {
        nft.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidityOwned(),
                amount0Min: 0,
                amount1Min: 0,
                deadline: uint256(-1)
            })
        );
        collect(to);
    }
}

