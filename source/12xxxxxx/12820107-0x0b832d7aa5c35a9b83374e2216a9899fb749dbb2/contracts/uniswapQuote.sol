pragma solidity >=0.7.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import './LiquidityAmounts.sol';

contract LiquidityQuoter is LiquidityAmounts {  
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) public pure returns (uint256) {
        return FullMath.mulDiv(a, b, denominator);
    }
}
