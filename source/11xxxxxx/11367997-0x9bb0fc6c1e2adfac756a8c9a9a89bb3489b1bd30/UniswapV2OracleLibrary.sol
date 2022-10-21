// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import './IUniswapV2Pair.sol';
import './FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair,
        bool isToken0
    ) internal view returns (uint priceCumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (isToken0) {
          priceCumulative = IUniswapV2Pair(pair).price0CumulativeLast();

          // if time has elapsed since the last update on the pair, mock the accumulated price values
          if (blockTimestampLast != blockTimestamp) {
              // subtraction overflow is desired
              uint32 timeElapsed = blockTimestamp - blockTimestampLast;
              // addition overflow is desired
              // counterfactual
              priceCumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
          }
        } else {
          priceCumulative = IUniswapV2Pair(pair).price1CumulativeLast();
          // if time has elapsed since the last update on the pair, mock the accumulated price values
          if (blockTimestampLast != blockTimestamp) {
              // subtraction overflow is desired
              uint32 timeElapsed = blockTimestamp - blockTimestampLast;
              // addition overflow is desired
              // counterfactual
              priceCumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
          }
        }

    }
    function getUniswapV2Pair(address _token0, address _token1) internal pure returns (address uni_pair, bool isToken0) {
        
        (address token0, address token1) = UniswapV2OracleLibrary.sortTokens(
            _token0,
            _token1
        );
        //bool _isToken0;
        // used for interacting with uniswap
        if (token0 == _token0) {
            isToken0 = true;
        } else {
            isToken0 = false;
        }

        uni_pair = UniswapV2OracleLibrary.pairFor(address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), token0, token1);

        return (uni_pair, isToken0);

    }
    /* - Constructor Helpers - */

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address token0,
        address token1
    ) internal pure returns (address pair) {
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }
}

