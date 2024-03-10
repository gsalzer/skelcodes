// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import {add, sub, wmul, wdiv} from "../../vendor/DSMath.sol";
import {
    INSTA_POOL_RESOLVER,
    ROUTE_1_TOLERANCE
} from "../../constants/CInstaDapp.sol";
import {GAS_COSTS_FOR_FULL_REFINANCE} from "../../constants/CDebtBridge.sol";
import {
    IInstaPoolResolver
} from "../../interfaces/InstaDapp/resolvers/IInstaPoolResolver.sol";

function _wCalcCollateralToWithdraw(
    uint256 _wMinColRatioA,
    uint256 _wMinColRatioB,
    uint256 _wColPrice,
    uint256 _wPricedCol,
    uint256 _wDebtOnA
) pure returns (uint256) {
    return
        wdiv(
            sub(
                _wPricedCol,
                wdiv(
                    sub(
                        wmul(_wMinColRatioA, _wPricedCol),
                        wmul(_wMinColRatioA, wmul(_wMinColRatioB, _wDebtOnA))
                    ),
                    sub(_wMinColRatioA, _wMinColRatioB)
                )
            ),
            _wColPrice
        );
}

function _wCalcDebtToRepay(
    uint256 _wMinColRatioA,
    uint256 _wMinColRatioB,
    uint256 _wPricedCol,
    uint256 _wDebtOnA
) pure returns (uint256) {
    return
        sub(
            _wDebtOnA,
            wmul(
                wdiv(1e18, _wMinColRatioA),
                wdiv(
                    sub(
                        wmul(_wMinColRatioA, _wPricedCol),
                        wmul(_wMinColRatioA, wmul(_wMinColRatioB, _wDebtOnA))
                    ),
                    sub(_wMinColRatioA, _wMinColRatioB)
                )
            )
        );
}

function _getFlashLoanRoute(address _tokenA, uint256 _wTokenADebtToMove)
    view
    returns (uint256)
{
    IInstaPoolResolver.RouteData memory rData = IInstaPoolResolver(
        INSTA_POOL_RESOLVER
    )
        .getTokenLimit(_tokenA);

    if (rData.dydx > _wTokenADebtToMove) return 0;
    if (rData.maker > _wTokenADebtToMove) return 1;
    if (rData.compound > _wTokenADebtToMove) return 2;
    if (rData.aave > _wTokenADebtToMove) return 3;
    revert("FGelatoDebtBridge._getFlashLoanRoute: illiquid");
}

function _getGasCostMakerToMaker(bool _newVault, uint256 _route)
    pure
    returns (uint256)
{
    _checkRouteIndex(_route);
    return
        _newVault
            ? add(GAS_COSTS_FOR_FULL_REFINANCE()[_route], 0)
            : GAS_COSTS_FOR_FULL_REFINANCE()[_route];
}

function _getGasCostMakerToCompound(uint256 _route) pure returns (uint256) {
    _checkRouteIndex(_route);
    return GAS_COSTS_FOR_FULL_REFINANCE()[_route];
}

function _getRealisedDebt(uint256 _debtToMove) pure returns (uint256) {
    return wmul(_debtToMove, ROUTE_1_TOLERANCE);
}

function _checkRouteIndex(uint256 _route) pure {
    require(
        _route <= 4,
        "FGelatoDebtBridge._getGasCostMakerToMaker: invalid route index"
    );
}

