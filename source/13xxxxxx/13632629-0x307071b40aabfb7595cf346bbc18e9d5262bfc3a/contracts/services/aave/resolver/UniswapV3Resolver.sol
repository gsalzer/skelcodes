// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {GelatoString} from "../../../lib/GelatoString.sol";
import {UniswapV3Data, UniswapV3Result} from "../../../structs/SUniswapV3.sol";
import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import {
    IUniswapV3Factory
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {
    QUOTER,
    LOW_FEES,
    MEDIUM_FEES,
    HIGH_FEES,
    FACTORY
} from "../../../constants/CUniswapV3.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {OK} from "../../../constants/CAaveServices.sol";
import {PoolKey} from "../../../structs/SUniswapV3.sol";

contract UniswapV3Resolver {
    using GelatoString for string;
    using Math for uint256;

    // should be called with callstatic of etherjs,
    // because quoteExactInputSingle is not a view function.
    function multicallGetAmountsOut(UniswapV3Data[] calldata datas_)
        public
        returns (UniswapV3Result[] memory results)
    {
        results = new UniswapV3Result[](datas_.length);

        for (uint256 i = 0; i < datas_.length; i++) {
            try this.getBestPool(datas_[i]) returns (
                UniswapV3Result memory result
            ) {
                results[i] = result;
            } catch Error(string memory error) {
                results[i] = UniswapV3Result({
                    id: datas_[i].id,
                    amountOut: 0,
                    fee: 0,
                    message: error.prefix(
                        "UniswapV3Resolver.getBestPool failed:"
                    )
                });
            } catch {
                results[i] = UniswapV3Result({
                    id: datas_[i].id,
                    amountOut: 0,
                    fee: 0,
                    message: "UniswapV3Resolver.getBestPool failed:undefined"
                });
            }
        }
    }

    function getBestPool(UniswapV3Data memory data_)
        public
        returns (UniswapV3Result memory)
    {
        uint256 amountOut = _quoteExactInputSingle(data_, LOW_FEES);
        uint24 fee = LOW_FEES;

        uint256 amountOutMediumFee;
        if (
            (amountOutMediumFee = _quoteExactInputSingle(data_, MEDIUM_FEES)) >
            amountOut
        ) {
            amountOut = amountOutMediumFee;
            fee = MEDIUM_FEES;
        }

        uint256 amountOutHighFee;
        if (
            (amountOutHighFee = _quoteExactInputSingle(data_, HIGH_FEES)) >
            amountOut
        ) {
            amountOut = amountOutHighFee;
            fee = HIGH_FEES;
        }

        return
            UniswapV3Result({
                id: data_.id,
                amountOut: amountOut,
                fee: fee,
                message: OK
            });
    }

    function _quoteExactInputSingle(UniswapV3Data memory data_, uint24 fee_)
        internal
        returns (uint256)
    {
        PoolKey memory poolKey = _getPoolKey(
            data_.tokenIn,
            data_.tokenOut,
            fee_
        );
        if (
            IUniswapV3Factory(FACTORY).getPool(
                poolKey.token0,
                poolKey.token1,
                poolKey.fee
            ) == address(0)
        ) return 0;
        return
            IQuoter(QUOTER).quoteExactInputSingle(
                data_.tokenIn,
                data_.tokenOut,
                fee_,
                data_.amountIn,
                0
            );
    }

    function _getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }
}

