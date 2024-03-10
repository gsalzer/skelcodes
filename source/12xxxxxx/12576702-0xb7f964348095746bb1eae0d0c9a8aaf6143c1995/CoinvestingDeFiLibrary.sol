// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./ICoinvestingDeFiPair.sol";
import "./SafeMath.sol";

library CoinvestingDeFiLibrary {
    using SafeMath for uint;
    // Internal functions that are view
    function getAmountsIn(
        address factory,
        uint amountOut,
        address[] memory path
    )
    internal
    view
    returns (uint[] memory amounts)
    {
        require(path.length >= 2, 'LIB: INV_P');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(
                factory, 
                path[i - 1], 
                path[i]
            );
            amounts[i - 1] = getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut
            );
        }
    }

    function getAmountsOut(
        address factory,
        uint amountIn,
        address[] memory path
    )
    internal
    view
    returns (uint[] memory amounts)
    {
        require(path.length >= 2, 'LIB: INV_P');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(
                factory, 
                path[i], 
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut
            );
        }
    }

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    )
    internal
    view
    returns (
        uint reserveA,
        uint reserveB
    )
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ICoinvestingDeFiPair(pairFor(
            factory,
            tokenA,
            tokenB
        )).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // Internal functions that are pure
    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    )
    internal
    pure
    returns (uint amountIn)
    {
        require(amountOut > 0, 'LIB: INSUF_OUT_AMT');
        require(reserveIn > 0 && reserveOut > 0, 'LIB: INSUF_LIQ');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }
    
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    )
    internal
    pure
    returns (uint amountOut)
    {
        require(amountIn > 0, 'LIB: INSUF_IN_AMT');
        require(reserveIn > 0 && reserveOut > 0, 'LIB: INSUF_LIQ');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    )
    internal
    pure
    returns (address pair) 
    {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'f414eaf687b005cd1d29be0b74430bb3d59f939715b3abbbb07af574ca27e22e' // init code hash
        )))));
    }

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    )
    internal
    pure
    returns (uint amountB)
    {
        require(amountA > 0, 'LIB: INSUF_AMT');
        require(reserveA > 0 && reserveB > 0, 'LIB: INSUF_LIQ');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function sortTokens(
        address tokenA,
        address tokenB
    )
    internal
    pure
    returns (
        address token0,
        address token1
    )
    {
        require(tokenA != tokenB, 'LIB: IDT_ADDR');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'LIB: ZERO_ADDR');
    }
}

