// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import {IGUniRouter02} from "./interfaces/IGUniRouter02.sol";
import {IGUniPool} from "./interfaces/IGUniPool.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {GelatoBytes} from "./vendor/gelato/GelatoBytes.sol";

contract GUniRouter02 is IGUniRouter02 {
    using Address for address payable;
    using SafeERC20 for IERC20;

    IWETH public immutable weth;

    constructor(IWETH _weth) {
        weth = _weth;
    }

    /// @notice addLiquidity adds liquidity to G-UNI pool of interest (mints G-UNI LP tokens)
    /// @param _pool address of G-UNI pool to add liquidity to
    /// @param _amount0Max the maximum amount of token0 msg.sender willing to input
    /// @param _amount1Max the maximum amount of token1 msg.sender willing to input
    /// @param _amount0Min the minimum amount of token0 actually input (slippage protection)
    /// @param _amount1Min the minimum amount of token1 actually input (slippage protection)
    /// @param _receiver account to receive minted G-UNI tokens
    /// @return amount0 amount of token0 transferred from msg.sender to mint `mintAmount`
    /// @return amount1 amount of token1 transferred from msg.sender to mint `mintAmount`
    /// @return mintAmount amount of G-UNI tokens minted and transferred to `receiver`
    function addLiquidity(
        IGUniPool _pool,
        uint256 _amount0Max,
        uint256 _amount1Max,
        uint256 _amount0Min,
        uint256 _amount1Min,
        address _receiver
    )
        external
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        (amount0, amount1, mintAmount) = _pool.getMintAmounts(
            _amount0Max,
            _amount1Max
        );
        require(
            amount0 >= _amount0Min && amount1 >= _amount1Min,
            "below min amounts"
        );
        if (amount0 > 0) {
            _pool.token0().safeTransferFrom(msg.sender, address(this), amount0);
        }
        if (amount1 > 0) {
            _pool.token1().safeTransferFrom(msg.sender, address(this), amount1);
        }

        _deposit(_pool, amount0, amount1, mintAmount, _receiver);
    }

    /// @notice addLiquidityETH same as addLiquidity but expects ETH transfers (instead of WETH)
    // solhint-disable-next-line code-complexity, function-max-lines
    function addLiquidityETH(
        IGUniPool _pool,
        uint256 _amount0Max,
        uint256 _amount1Max,
        uint256 _amount0Min,
        uint256 _amount1Min,
        address _receiver
    )
        external
        payable
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        (amount0, amount1, mintAmount) = _pool.getMintAmounts(
            _amount0Max,
            _amount1Max
        );
        require(
            amount0 >= _amount0Min && amount1 >= _amount1Min,
            "below min amounts"
        );

        if (isToken0Weth(address(_pool.token0()), address(_pool.token1()))) {
            require(
                _amount0Max == msg.value,
                "mismatching amount of ETH forwarded"
            );
            if (amount0 > 0) {
                weth.deposit{value: amount0}();
            }
            if (amount1 > 0) {
                _pool.token1().safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount1
                );
            }
        } else {
            require(
                _amount1Max == msg.value,
                "mismatching amount of ETH forwarded"
            );
            if (amount1 > 0) {
                weth.deposit{value: amount1}();
            }
            if (amount0 > 0) {
                _pool.token0().safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount0
                );
            }
        }

        _deposit(_pool, amount0, amount1, mintAmount, _receiver);

        if (address(this).balance > 0) {
            payable(msg.sender).sendValue(address(this).balance);
        }
    }

    /// @notice rebalanceAndAddLiquidity accomplishes same task as addLiquidity/addLiquidityETH
    /// but we rebalance msg.sender's holdings (perform a swap) before adding liquidity.
    /// @param _pool address of G-UNI pool to add liquidity to
    /// @param _amount0In the amount of token0 msg.sender forwards to router
    /// @param _amount1In the amount of token1 msg.sender forwards to router
    /// @param _amountSwap amount to input into swap
    /// @param _zeroForOne directionality of swap
    /// @param _swapActions addresses for swap calls
    /// @param _swapDatas payloads for swap calls
    /// @param _amount0Min the minimum amount of token0 actually deposited (slippage protection)
    /// @param _amount1Min the minimum amount of token1 actually deposited (slippage protection)
    /// @param _receiver account to receive minted G-UNI tokens
    /// @return amount0 amount of token0 actually deposited into pool
    /// @return amount1 amount of token1 actually deposited into pool
    /// @return mintAmount amount of G-UNI tokens minted and transferred to `receiver`
    /// @dev note on swaps: MUST swap to/from token0 from/to token1 as specified by zeroForOne
    /// will revert on "overshot" swap (receive more outToken from swap than can be deposited)
    /// swapping for erroneous tokens will not necessarily revert in all cases
    /// and could result in loss of funds so be careful with swapActions and swapDatas params.
    // solhint-disable-next-line function-max-lines
    function rebalanceAndAddLiquidity(
        IGUniPool _pool,
        uint256 _amount0In,
        uint256 _amount1In,
        uint256 _amountSwap,
        bool _zeroForOne,
        address[] memory _swapActions,
        bytes[] memory _swapDatas,
        uint256 _amount0Min,
        uint256 _amount1Min,
        address _receiver
    )
        external
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        (amount0, amount1, mintAmount) = _prepareRebalanceDeposit(
            _pool,
            _amount0In,
            _amount1In,
            _amountSwap,
            _zeroForOne,
            _swapActions,
            _swapDatas
        );
        require(
            amount0 >= _amount0Min && amount1 >= _amount1Min,
            "below min amounts"
        );

        _deposit(_pool, amount0, amount1, mintAmount, _receiver);
    }

    /// @notice rebalanceAndAddLiquidityETH same as rebalanceAndAddLiquidity
    /// except this function expects ETH transfer (instead of WETH)
    /// @dev note on swaps: MUST swap either ETH -> token or token->WETH
    /// swaps which try to execute token -> ETH instead of WETH will revert
    // solhint-disable-next-line function-max-lines, code-complexity
    function rebalanceAndAddLiquidityETH(
        IGUniPool _pool,
        uint256 _amount0In,
        uint256 _amount1In,
        uint256 _amountSwap,
        bool _zeroForOne,
        address[] memory _swapActions,
        bytes[] memory _swapDatas,
        uint256 _amount0Min,
        uint256 _amount1Min,
        address _receiver
    )
        external
        payable
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        (amount0, amount1, mintAmount) = _prepareRebalanceDepositETH(
            _pool,
            _amount0In,
            _amount1In,
            _amountSwap,
            _zeroForOne,
            _swapActions,
            _swapDatas
        );
        require(
            amount0 >= _amount0Min && amount1 >= _amount1Min,
            "below min amounts"
        );

        _deposit(_pool, amount0, amount1, mintAmount, _receiver);

        if (address(this).balance > 0) {
            payable(msg.sender).sendValue(address(this).balance);
        }
    }

    /// @notice removeLiquidity removes liquidity from a G-UNI pool and burns G-UNI LP tokens
    /// @param _pool address of G-UNI pool to remove liquidity from
    /// @param _burnAmount The number of G-UNI tokens to burn
    /// @param _amount0Min Minimum amount of token0 received after burn (slippage protection)
    /// @param _amount1Min Minimum amount of token1 received after burn (slippage protection)
    /// @param _receiver The account to receive the underlying amounts of token0 and token1
    /// @return amount0 actual amount of token0 transferred to receiver for burning `burnAmount`
    /// @return amount1 actual amount of token1 transferred to receiver for burning `burnAmount`
    /// @return liquidityBurned amount of liquidity removed from the underlying Uniswap V3 position
    function removeLiquidity(
        IGUniPool _pool,
        uint256 _burnAmount,
        uint256 _amount0Min,
        uint256 _amount1Min,
        address _receiver
    )
        external
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        )
    {
        IERC20(address(_pool)).safeTransferFrom(
            msg.sender,
            address(this),
            _burnAmount
        );
        (amount0, amount1, liquidityBurned) = _pool.burn(
            _burnAmount,
            _receiver
        );
        require(
            amount0 >= _amount0Min && amount1 >= _amount1Min,
            "received below minimum"
        );
    }

    /// @notice removeLiquidityETH same as removeLiquidity
    /// except this function unwraps WETH and sends ETH to receiver account
    // solhint-disable-next-line code-complexity, function-max-lines
    function removeLiquidityETH(
        IGUniPool _pool,
        uint256 _burnAmount,
        uint256 _amount0Min,
        uint256 _amount1Min,
        address payable _receiver
    )
        external
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        )
    {
        bool wethToken0 =
            isToken0Weth(address(_pool.token0()), address(_pool.token1()));

        IERC20(address(_pool)).safeTransferFrom(
            msg.sender,
            address(this),
            _burnAmount
        );
        (amount0, amount1, liquidityBurned) = _pool.burn(
            _burnAmount,
            address(this)
        );
        require(
            amount0 >= _amount0Min && amount1 >= _amount1Min,
            "received below minimum"
        );

        if (wethToken0) {
            if (amount0 > 0) {
                weth.withdraw(amount0);
                _receiver.sendValue(amount0);
            }
            if (amount1 > 0) {
                _pool.token1().safeTransfer(_receiver, amount1);
            }
        } else {
            if (amount1 > 0) {
                weth.withdraw(amount1);
                _receiver.sendValue(amount1);
            }
            if (amount0 > 0) {
                _pool.token0().safeTransfer(_receiver, amount0);
            }
        }
    }

    function _deposit(
        IGUniPool _pool,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _mintAmount,
        address _receiver
    ) internal {
        if (_amount0 > 0) {
            _pool.token0().safeIncreaseAllowance(address(_pool), _amount0);
        }
        if (_amount1 > 0) {
            _pool.token1().safeIncreaseAllowance(address(_pool), _amount1);
        }

        (uint256 amount0Check, uint256 amount1Check, ) =
            _pool.mint(_mintAmount, _receiver);
        require(
            _amount0 == amount0Check && _amount1 == amount1Check,
            "unexpected amounts deposited"
        );
    }

    // solhint-disable-next-line function-max-lines
    function _prepareRebalanceDeposit(
        IGUniPool _pool,
        uint256 _amount0In,
        uint256 _amount1In,
        uint256 _amountSwap,
        bool _zeroForOne,
        address[] memory _swapActions,
        bytes[] memory _swapDatas
    )
        internal
        returns (
            uint256 amount0Use,
            uint256 amount1Use,
            uint256 mintAmount
        )
    {
        if (_zeroForOne) {
            _pool.token0().safeTransferFrom(
                msg.sender,
                address(this),
                _amountSwap
            );
            _amount0In = _amount0In - _amountSwap;
        } else {
            _pool.token1().safeTransferFrom(
                msg.sender,
                address(this),
                _amountSwap
            );
            _amount1In = _amount1In - _amountSwap;
        }

        (uint256 balance0, uint256 balance1) =
            _swap(_pool, 0, _zeroForOne, _swapActions, _swapDatas);

        (amount0Use, amount1Use, mintAmount) = _postSwap(
            _pool,
            _amount0In,
            _amount1In,
            balance0,
            balance1
        );
    }

    // solhint-disable-next-line function-max-lines
    function _prepareRebalanceDepositETH(
        IGUniPool _pool,
        uint256 _amount0In,
        uint256 _amount1In,
        uint256 _amountSwap,
        bool _zeroForOne,
        address[] memory _swapActions,
        bytes[] memory _swapDatas
    )
        internal
        returns (
            uint256 amount0Use,
            uint256 amount1Use,
            uint256 mintAmount
        )
    {
        bool wethToken0 =
            isToken0Weth(address(_pool.token0()), address(_pool.token1()));

        if (_zeroForOne) {
            if (wethToken0) {
                require(
                    _amount0In == msg.value,
                    "mismatching amount of ETH forwarded"
                );
            } else {
                _pool.token0().safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amountSwap
                );
            }
            _amount0In = _amount0In - _amountSwap;
        } else {
            if (wethToken0) {
                _pool.token1().safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amountSwap
                );
            } else {
                require(
                    _amount1In == msg.value,
                    "mismatching amount of ETH forwarded"
                );
            }
            _amount1In = _amount1In - _amountSwap;
        }

        (uint256 balance0, uint256 balance1) =
            _swap(
                _pool,
                wethToken0 == _zeroForOne ? _amountSwap : 0,
                _zeroForOne,
                _swapActions,
                _swapDatas
            );

        (amount0Use, amount1Use, mintAmount) = _postSwapETH(
            _pool,
            _amount0In,
            _amount1In,
            balance0,
            balance1,
            wethToken0
        );
    }

    // solhint-disable-next-line code-complexity
    function _swap(
        IGUniPool _pool,
        uint256 _ethValue,
        bool _zeroForOne,
        address[] memory _swapActions,
        bytes[] memory _swapDatas
    ) internal returns (uint256 balance0, uint256 balance1) {
        require(
            _swapActions.length == _swapDatas.length,
            "swap actions length != swap datas length"
        );
        uint256 balanceBefore =
            _zeroForOne
                ? _pool.token1().balanceOf(address(this))
                : _pool.token0().balanceOf(address(this));

        if (_ethValue > 0 && _swapActions.length == 1) {
            (bool success, bytes memory returnsData) =
                _swapActions[0].call{value: _ethValue}(_swapDatas[0]);
            if (!success) GelatoBytes.revertWithError(returnsData, "swap: ");
        } else {
            for (uint256 i; i < _swapActions.length; i++) {
                (bool success, bytes memory returnsData) =
                    _swapActions[i].call(_swapDatas[i]);
                if (!success)
                    GelatoBytes.revertWithError(returnsData, "swap: ");
            }
        }
        balance0 = _pool.token0().balanceOf(address(this));
        balance1 = _pool.token1().balanceOf(address(this));
        if (_zeroForOne) {
            require(balance1 > balanceBefore, "swap for incorrect token");
        } else {
            require(balance0 > balanceBefore, "swap for incorrect token");
        }
    }

    // solhint-disable-next-line function-max-lines
    function _postSwap(
        IGUniPool _pool,
        uint256 _amount0In,
        uint256 _amount1In,
        uint256 _balance0,
        uint256 _balance1
    )
        internal
        returns (
            uint256 amount0Use,
            uint256 amount1Use,
            uint256 mintAmount
        )
    {
        (amount0Use, amount1Use, mintAmount) = _pool.getMintAmounts(
            _amount0In + _balance0,
            _amount1In + _balance1
        );

        if (_balance0 > amount0Use) {
            _pool.token0().safeTransfer(msg.sender, _balance0 - amount0Use);
        } else if (_balance0 < amount0Use) {
            _pool.token0().safeTransferFrom(
                msg.sender,
                address(this),
                amount0Use - _balance0
            );
        }

        if (_balance1 > amount1Use) {
            _pool.token1().safeTransfer(msg.sender, _balance1 - amount1Use);
        } else if (_balance1 < amount1Use) {
            _pool.token1().safeTransferFrom(
                msg.sender,
                address(this),
                amount1Use - _balance1
            );
        }
    }

    // solhint-disable-next-line code-complexity, function-max-lines
    function _postSwapETH(
        IGUniPool _pool,
        uint256 _amount0In,
        uint256 _amount1In,
        uint256 _balance0,
        uint256 _balance1,
        bool _wethToken0
    )
        internal
        returns (
            uint256 amount0Use,
            uint256 amount1Use,
            uint256 mintAmount
        )
    {
        (amount0Use, amount1Use, mintAmount) = _pool.getMintAmounts(
            _amount0In + _balance0,
            _amount1In + _balance1
        );

        if (amount0Use > _balance0) {
            if (_wethToken0) {
                weth.deposit{value: amount0Use - _balance0}();
            } else {
                _pool.token0().safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount0Use - _balance0
                );
            }
        } else if (_balance0 > amount0Use) {
            if (_wethToken0) {
                weth.withdraw(_balance0 - amount0Use);
            } else {
                _pool.token0().safeTransfer(msg.sender, _balance0 - amount0Use);
            }
        }
        if (amount1Use > _balance1) {
            if (_wethToken0) {
                _pool.token1().safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount1Use - _balance1
                );
            } else {
                weth.deposit{value: amount1Use - _balance1}();
            }
        } else if (_balance1 > amount1Use) {
            if (_wethToken0) {
                _pool.token1().safeTransfer(msg.sender, _balance1 - amount1Use);
            } else {
                weth.withdraw(_balance1 - amount1Use);
            }
        }
    }

    function isToken0Weth(address _token0, address _token1)
        public
        view
        returns (bool wethToken0)
    {
        if (_token0 == address(weth)) {
            wethToken0 = true;
        } else if (_token1 == address(weth)) {
            wethToken0 = false;
        } else {
            revert("one pool token must be WETH");
        }
    }

    receive() external payable {
        require(
            msg.sender == address(weth),
            "only receive ETH from WETH address"
        );
    }
}

