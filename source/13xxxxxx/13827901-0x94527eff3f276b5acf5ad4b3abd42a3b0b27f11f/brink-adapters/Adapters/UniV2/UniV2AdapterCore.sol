// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import '../../Libraries/TransferHelper.sol';
import "../Withdrawable.sol";
import "../ISwapAdapter.sol";
import "../IWETH.sol";
import "./UniswapV2Library.sol";

abstract contract UniV2AdapterCore is ISwapAdapter, Withdrawable {
  IWETH public weth;
  address public factory;
  bool public initialized;

  function initialize (IWETH _weth, address _factory) external onlyOwner {
    require(!initialized, 'INITIALIZED');
    initialized = true;
    weth = _weth;
    factory = _factory;
  }

  function tokenToTokenOutputAmount(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenInAmount
  ) public view override virtual returns (uint tokenOutAmount) {
    tokenOutAmount = _amountOut(tokenIn, tokenOut, tokenInAmount);
  }

  function tokenToTokenInputAmount(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenOutAmount
  ) public view override virtual returns (uint tokenInAmount) {
    tokenInAmount = _amountIn(tokenIn, tokenOut, tokenOutAmount);
  }

  function ethToTokenOutputAmount(
    IERC20 token,
    uint ethInAmount
  ) public view override virtual returns (uint tokenOutAmount) {
    tokenOutAmount = _amountOut(IERC20(address(weth)), token, ethInAmount);
  }

  function ethToTokenInputAmount(
    IERC20 token,
    uint tokenOutAmount
  ) public view override virtual returns (uint ethInAmount) {
    ethInAmount = _amountIn(IERC20(address(weth)), token, tokenOutAmount);
  }

  function tokenToEthOutputAmount(
    IERC20 token,
    uint tokenInAmount
  ) public view override virtual returns (uint ethOutAmount) {
    ethOutAmount = _amountOut(token, IERC20(address(weth)), tokenInAmount);
  }

  function tokenToEthInputAmount(
    IERC20 token,
    uint ethOutAmount
  ) public view override virtual returns (uint tokenInAmount) {
    tokenInAmount = _amountIn(token, IERC20(address(weth)), ethOutAmount);
  }

  function _singlePairSwap(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount, address to)
   internal
  {
    _swap(_amounts(tokenInAmount, tokenOutAmount), _path(tokenIn, tokenOut), to);
  }

  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0,) = UniswapV2Library.sortTokens(input, output);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
      IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

  function _transferInputToPair(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount) internal {
    TransferHelper.safeTransfer(
      address(tokenIn),
      UniswapV2Library.pairFor(factory, address(tokenIn), address(tokenOut)),
      tokenInAmount
    );
  }

  function _amountOut(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount)
    internal view
    returns (uint tokenOutAmount)
  {
    address[] memory path = _path(tokenIn, tokenOut);
    tokenOutAmount = UniswapV2Library.getAmountsOut(factory, tokenInAmount, path)[1];
  }

  function _amountIn(IERC20 tokenIn, IERC20 tokenOut, uint tokenOutAmount)
    internal view
    returns (uint tokenInAmount)
  {
    address[] memory path = _path(tokenIn, tokenOut);
    tokenInAmount = UniswapV2Library.getAmountsIn(factory, tokenOutAmount, path)[0];
  }

  function _path (IERC20 tokenIn, IERC20 tokenOut)
    internal pure
    returns (address[] memory path)
  {
    path = new address[](2);
    path[0] = address(tokenIn);
    path[1] = address(tokenOut);
  }

  function _amounts (uint amountIn, uint amountOut)
    internal pure
    returns (uint[] memory amounts)
  {
    amounts = new uint[](2);
    amounts[0] = amountIn;
    amounts[1] = amountOut;
  }

}

