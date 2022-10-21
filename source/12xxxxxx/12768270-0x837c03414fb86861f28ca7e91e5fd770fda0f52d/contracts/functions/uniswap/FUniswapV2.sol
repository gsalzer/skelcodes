// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {GelatoString} from "../../lib/GelatoString.sol";
import {
    IUniswapV2Router02
} from "../../interfaces/uniswap/IUniswapV2Router02.sol";
import {ETH} from "../../constants/Tokens.sol";

function _swapExactXForX(
    address WETH, // solhint-disable-line var-name-mixedcase
    IUniswapV2Router02 _uniRouter,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path,
    address _to,
    uint256 _deadline
) returns (uint256) {
    if (_path[0] == ETH) {
        _path[0] = WETH;
        return
            _swapExactETHForTokens(
                _uniRouter,
                _amountIn,
                _amountOutMin,
                _path,
                _to,
                _deadline
            );
    }

    SafeERC20.safeIncreaseAllowance(
        IERC20(_path[0]),
        address(_uniRouter),
        _amountIn
    );

    if (_path[_path.length - 1] == ETH) {
        _path[_path.length - 1] = WETH;
        return
            _swapExactTokensForETH(
                _uniRouter,
                _amountIn,
                _amountOutMin,
                _path,
                _to,
                _deadline
            );
    }

    return
        _swapExactTokensForTokens(
            _uniRouter,
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            _deadline
        );
}

function _swapExactETHForTokens(
    IUniswapV2Router02 _uniRouter,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path, // must be ETH-WETH SANITIZED!
    address _to,
    uint256 _deadline
) returns (uint256 amountOut) {
    try
        _uniRouter.swapExactETHForTokens{value: _amountIn}(
            _amountOutMin,
            _path,
            _to,
            _deadline
        )
    returns (uint256[] memory amounts) {
        amountOut = amounts[amounts.length - 1];
    } catch Error(string memory error) {
        GelatoString.revertWithInfo(error, "_swapExactETHForTokens:");
    } catch {
        revert("_swapExactETHForTokens:undefined");
    }
}

function _swapExactTokensForETH(
    IUniswapV2Router02 _uniRouter,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path, // must be ETH-WETH SANITIZED!
    address _to,
    uint256 _deadline
) returns (uint256 amountOut) {
    try
        _uniRouter.swapExactTokensForETH(
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            _deadline
        )
    returns (uint256[] memory amounts) {
        amountOut = amounts[amounts.length - 1];
    } catch Error(string memory error) {
        GelatoString.revertWithInfo(error, "_swapExactTokensForETH:");
    } catch {
        revert("_swapExactTokensForETH:undefined");
    }
}

function _swapExactTokensForTokens(
    IUniswapV2Router02 _uniRouter,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path, // must be ETH-WETH SANITIZED!
    address _to,
    uint256 _deadline
) returns (uint256 amountOut) {
    try
        _uniRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            _deadline
        )
    returns (uint256[] memory amounts) {
        amountOut = amounts[amounts.length - 1];
    } catch Error(string memory error) {
        GelatoString.revertWithInfo(error, "_swapExactTokensForTokens:");
    } catch {
        revert("_swapExactTokensForTokens:undefined");
    }
}

function _swapTokensForExactETH(
    IUniswapV2Router02 _uniRouter,
    uint256 _amountOut,
    uint256 _amountInMax,
    address[] memory _path, // must be ETH-WETH SANITIZED!
    address _to,
    uint256 _deadline
) returns (uint256 amountIn) {
    SafeERC20.safeIncreaseAllowance(
        IERC20(_path[0]),
        address(_uniRouter),
        _amountInMax
    );

    try
        _uniRouter.swapTokensForExactETH(
            _amountOut,
            _amountInMax,
            _path,
            _to,
            _deadline
        )
    returns (uint256[] memory amounts) {
        return amounts[0];
    } catch Error(string memory error) {
        GelatoString.revertWithInfo(error, "_swapTokensForExactETH:");
    } catch {
        revert("_swapTokensForExactETH:undefined");
    }
}

