// SPDX-License-Identifier: GPL3

pragma solidity 0.8.0;

import './IERC1155Receiver.sol';
import './IMateriaFactory.sol';
import './IERC20.sol';
import './IERC20WrapperV1.sol';
import './IDoubleProxy.sol';

interface IMateriaOrchestrator is IERC1155Receiver {
    function setDoubleProxy(address newDoubleProxy) external;

    function setBridgeToken(address newBridgeToken) external;

    function setErc20Wrapper(address newErc20Wrapper) external;

    function setFactory(address newFactory) external;

    function setEthereumObjectId(uint256 newEthereumObjectId) external;

    function setSwapper(address _swapper) external;

    function setLiquidityAdder(address _adder) external;

    function setLiquidityRemover(address _remover) external;

    function retire(address newOrchestrator) external;

    function setFees(
        address token,
        uint256 materiaFee,
        uint256 swapFee
    ) external;

    function setDefaultFees(uint256 materiaFee, uint256 swapFee) external;

    function setFeeTo(address feeTo) external;

    function getCrumbs(
        address token,
        uint256 amount,
        address receiver
    ) external;

    function factory() external view returns (IMateriaFactory);

    function bridgeToken() external view returns (IERC20);

    function erc20Wrapper() external view returns (IERC20WrapperV1);

    function ETHEREUM_OBJECT_ID() external view returns (uint256);

    function swapper() external view returns (address);

    function liquidityAdder() external view returns (address);

    function liquidityRemover() external view returns (address);

    function doubleProxy() external view returns (IDoubleProxy);

    //Liquidity adding

    function addLiquidity(
        address token,
        uint256 tokenAmountDesired,
        uint256 bridgeAmountDesired,
        uint256 tokenAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        uint256 bridgeAmountDesired,
        uint256 EthAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    //Liquidity removing

    function removeLiquidity(
        address token,
        uint256 liquidity,
        uint256 tokenAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline
    ) external;

    function removeLiquidityETH(
        uint256 liquidity,
        uint256 bridgeAmountMin,
        uint256 EthAmountMin,
        address to,
        uint256 deadline
    ) external;

    function removeLiquidityWithPermit(
        address token,
        uint256 liquidity,
        uint256 tokenAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function removeLiquidityETHWithPermit(
        uint256 liquidity,
        uint256 ethAmountMin,
        uint256 bridgeAmountMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    //Swapping

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external payable;

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] memory path,
        address to,
        uint256 deadline
    ) external payable;

    //Materia utilities

    function isEthItem(address token)
        external
        view
        returns (
            address collection,
            bool ethItem,
            uint256 itemId
        );

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);
}

