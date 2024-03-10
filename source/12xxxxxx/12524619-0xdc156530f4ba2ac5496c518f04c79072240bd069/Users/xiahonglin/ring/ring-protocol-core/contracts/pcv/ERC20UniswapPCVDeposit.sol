// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./UniswapPCVDeposit.sol";

/// @title implementation for an ETH Uniswap LP PCV Deposit
/// @author Ring Protocol
contract ERC20UniswapPCVDeposit is UniswapPCVDeposit {
    using Address for address payable;
    using SafeCast for uint256;

    /// @notice ETH Uniswap PCV Deposit constructor
    /// @param _core Ring Core for reference
    /// @param _pool Uniswap V3 Pool to deposit to
    /// @param _nft Uniswap V3 position manager to reference
    /// @param _router Uniswap Router
    /// @param _oracle oracle for reference
    constructor(
        address _core,
        address _pool,
        address _nft,
        address _router,
        address _oracle,
        int24 _tickLower,
        int24 _tickUpper
    ) UniswapPCVDeposit(_core, _pool, _nft, _router, _oracle) {
        tickLower = _tickLower;
        tickUpper = _tickUpper;
    }

    /// @notice deposit tokens into the PCV allocation
    function deposit() external payable override whenNotPaused {
        uint256 erc20AmountBalance = IERC20(token()).balanceOf(address(this)); // include any ERC20 dust from prior LP

        uint256 rusdAmount = _getAmountRusdToDeposit(erc20AmountBalance);

        _addLiquidity(erc20AmountBalance, rusdAmount);

        _burnRusdHeld(); // burn any RUSD dust from LP

        emit Deposit(msg.sender, erc20AmountBalance);
    }

    /// @notice collect fee income
    function collect() public override whenNotPaused returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = nft.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: uint128(-1),
                amount1Max: uint128(-1)
            })
        );

        emit Collect(address(this), amount0, amount1);
    }

    function _removeLiquidity(uint128 liquidity) internal override {
        uint256 endOfTime = uint256(-1);
        nft.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: endOfTime
            })
        );
        collect();
    }

    function _transferWithdrawn(address to) internal override {
        uint256 balance = IERC20(token()).balanceOf(address(this));
        TransferHelper.safeTransfer(token(), to, balance);
    }

    function _addLiquidity(uint256 erc20Amount, uint256 rusdAmount) internal {
        _mintRusd(rusdAmount);

        uint256 endOfTime = uint256(-1);
        address rusdAddress = address(rusd());
        address tokenAddress = token();
        (address token0, address token1) = rusdAddress < tokenAddress ? (rusdAddress, tokenAddress) : (tokenAddress, rusdAddress);
        (uint256 amount0Desired, uint256 amount1Desired) = rusdAddress < tokenAddress ? (rusdAmount, erc20Amount) : (erc20Amount, rusdAmount);
        if (tokenId == 0) {
            (tokenId, , ,) = nft.mint(
                INonfungiblePositionManager.MintParams({
                    token0: token0,
                    token1: token1,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    amount0Desired: amount0Desired,
                    amount1Desired: amount1Desired,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: address(this),
                    deadline: endOfTime,
                    fee: fee
                })
            );
        } else {
            if (amount0Desired > 0 || amount1Desired > 0) {
                nft.increaseLiquidity(
                    INonfungiblePositionManager.IncreaseLiquidityParams({
                        tokenId: tokenId,
                        amount0Desired: amount0Desired,
                        amount1Desired: amount1Desired,
                        amount0Min: 0,
                        amount1Min: 0,
                        deadline: endOfTime
                    })
                );
            }
        }
    }
}

