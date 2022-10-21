// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {wmul, wdiv} from "../../vendor/DSMath.sol";
import {
    INSTA_POOL_RESOLVER,
    ROUTE_1_TOLERANCE
} from "../../constants/CInstaDapp.sol";
import {DebtBridgeInputData} from "../../structs/SDebtBridge.sol";
import {
    _canDoMakerToAaveDebtBridge,
    _canDoMakerToMakerDebtBridge,
    _canDoMakerToCompoundDebtBridge
} from "./conditions/FCanDoRefinance.sol";
import {
    PROTOCOL,
    GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_MAKER,
    GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_COMPOUND,
    GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_AAVE,
    FAST_TX_FEE,
    VAULT_CREATION_COST
} from "../../constants/CDebtBridge.sol";
import {
    IInstaPoolResolver
} from "../../interfaces/InstaDapp/resolvers/IInstaPoolResolver.sol";
import {_getMakerVaultDebt} from "../dapps/FMaker.sol";
import {_getGelatoExecutorFees} from "./FGelato.sol";
import {DAI, ETH} from "../../constants/CTokens.sol";
import {IOracleAggregator} from "../../interfaces/gelato/IOracleAggregator.sol";
import {_convertTo18} from "../../vendor/Convert.sol";

function _getFlashLoanRoute(address _debtToken, uint256 _debtAmt)
    view
    returns (uint256)
{
    IInstaPoolResolver.RouteData memory rData =
        IInstaPoolResolver(INSTA_POOL_RESOLVER).getTokenLimit(_debtToken);

    if (rData.dydx > _debtAmt) return 0;
    if (rData.maker > _debtAmt) return 1;
    if (rData.compound > _debtAmt) return 2;
    if (rData.aave > _debtAmt) return 3;
    revert("FGelatoDebtBridge._getFlashLoanRoute: illiquid");
}

function _getDebtBridgeRoute(DebtBridgeInputData memory _data)
    view
    returns (PROTOCOL)
{
    if (_canDoMakerToAaveDebtBridge(_data)) return PROTOCOL.AAVE;
    else if (_canDoMakerToMakerDebtBridge(_data)) return PROTOCOL.MAKER;
    else if (_canDoMakerToCompoundDebtBridge(_data)) return PROTOCOL.COMPOUND;
    return PROTOCOL.NONE;
}

function _getGasCostMakerToMaker(bool _newVault, uint256 _route)
    pure
    returns (uint256)
{
    _checkRouteIndex(
        _route,
        "FGelatoDebtBridge._getGasCostMakerToMaker: invalid route index"
    );
    return
        _getGasCostPremium(
            _newVault
                ? GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_MAKER()[_route] +
                    VAULT_CREATION_COST
                : GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_MAKER()[_route]
        );
}

function _getGasCostMakerToCompound(uint256 _route) pure returns (uint256) {
    _checkRouteIndex(
        _route,
        "FGelatoDebtBridge._getGasCostMakerToCompound: invalid route index"
    );
    return
        _getGasCostPremium(
            GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_COMPOUND()[_route]
        );
}

function _getGasCostMakerToAave(uint256 _route) pure returns (uint256) {
    _checkRouteIndex(
        _route,
        "FGelatoDebtBridge._getGasCostMakerToAave: invalid route index"
    );
    return
        _getGasCostPremium(
            GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_AAVE()[_route]
        );
}

function _getGasCostPremium(uint256 _rawGasCost) pure returns (uint256) {
    return (_rawGasCost * (100 + FAST_TX_FEE)) / 100;
}

function _getRealisedDebt(uint256 _debtToMove) pure returns (uint256) {
    return wmul(_debtToMove, ROUTE_1_TOLERANCE);
}

function _checkRouteIndex(uint256 _route, string memory _revertMsg) pure {
    require(_route <= 4, _revertMsg);
}

function _getMaxAmtToBorrowMakerToAave(
    uint256 _fromVaultId,
    uint256 _fees,
    address _oracleAggregator
) view returns (uint256) {
    uint256 wDaiToBorrow = _getRealisedDebt(_getMakerVaultDebt(_fromVaultId));

    return
        _getMaxAmtToBorrow(
            wDaiToBorrow,
            _getGasCostMakerToAave(_getFlashLoanRoute(DAI, wDaiToBorrow)),
            _fees,
            _oracleAggregator
        );
}

function _getMaxAmtToBorrowMakerToCompound(
    uint256 _fromVaultId,
    uint256 _fees,
    address _oracleAggregator
) view returns (uint256) {
    uint256 wDaiToBorrow = _getRealisedDebt(_getMakerVaultDebt(_fromVaultId));

    return
        _getMaxAmtToBorrow(
            wDaiToBorrow,
            _getGasCostMakerToCompound(_getFlashLoanRoute(DAI, wDaiToBorrow)),
            _fees,
            _oracleAggregator
        );
}

function _getMaxAmtToBorrowMakerToMaker(
    uint256 _fromVaultId,
    bool _newVault,
    uint256 _fees,
    address _oracleAggregator
) view returns (uint256) {
    uint256 wDaiToBorrow = _getRealisedDebt(_getMakerVaultDebt(_fromVaultId));

    return
        _getMaxAmtToBorrow(
            wDaiToBorrow,
            _getGasCostMakerToMaker(
                _newVault,
                _getFlashLoanRoute(DAI, wDaiToBorrow)
            ),
            _fees,
            _oracleAggregator
        );
}

function _getMaxAmtToBorrow(
    uint256 _wDaiToBorrow,
    uint256 _gasCost,
    uint256 _fees,
    address _oracleAggregator
) view returns (uint256) {
    (uint256 gasCostInDAI, uint256 decimals) =
        IOracleAggregator(_oracleAggregator).getExpectedReturnAmount(
            _getGelatoExecutorFees(_gasCost),
            ETH,
            DAI
        );

    gasCostInDAI = _convertTo18(decimals, gasCostInDAI);

    return _wDaiToBorrow + gasCostInDAI + wmul(_wDaiToBorrow, _fees);
}

