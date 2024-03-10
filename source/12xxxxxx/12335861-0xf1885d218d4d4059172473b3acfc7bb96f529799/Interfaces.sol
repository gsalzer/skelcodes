// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

interface IGriseToken {

    function currentLPDay()
        external view
        returns (uint64);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function mintSupply(
        address _investorAddress,
        uint256 _amount
    ) external;
}

interface UniswapRouterV2 {

    function addLiquidityETH(
        address token,
        uint256 amountTokenMax,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (
        uint256[] memory amounts
    );
}

interface RefundSponsorI {
    function addGasRefund(address _a, uint256 _c) external;
}

interface IERC20Token {

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )  external returns (
        bool success
    );

    function approve(
        address _spender,
        uint256 _value
    )  external returns (
        bool success
    );
}

