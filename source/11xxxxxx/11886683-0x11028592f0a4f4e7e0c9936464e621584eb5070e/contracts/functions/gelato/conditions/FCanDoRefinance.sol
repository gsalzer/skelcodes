// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {_isAaveLiquid} from "./aave/FAaveHasLiquidity.sol";
import {_aavePositionWillBeSafe} from "./aave/FAavePositionWillBeSafe.sol";
import {_isDebtAmtDust} from "./maker/FIsDebtAmtDust.sol";
import {_isDebtCeilingReached} from "./maker/FDebtCeilingIsReached.sol";
import {_destVaultWillBeSafe} from "./maker/FDestVaultWillBeSafe.sol";
import {_cTokenHasLiquidity} from "./compound/FCompoundHasLiquidity.sol";
import {
    _compoundPositionWillBeSafe
} from "./compound/FCompoundPositionWillBeSafe.sol";
import {DebtBridgeInputData} from "../../../structs/SDebtBridge.sol";
import {DAI} from "../../../constants/CTokens.sol";
import {
    _getMaxAmtToBorrow,
    _getGasCostMakerToAave,
    _getGasCostMakerToCompound,
    _getGasCostMakerToMaker
} from "../FGelatoDebtBridge.sol";

function _canDoMakerToAaveDebtBridge(DebtBridgeInputData memory _data)
    view
    returns (bool)
{
    uint256 maxBorToAavePos =
        _getMaxAmtToBorrow(
            _data.debtAmt,
            _getGasCostMakerToAave(_data.flashRoute),
            _data.fees,
            _data.oracleAggregator
        );
    return
        _isAaveLiquid(DAI, maxBorToAavePos) &&
        _aavePositionWillBeSafe(
            _data.dsa,
            _data.colAmt,
            _data.colToken,
            maxBorToAavePos,
            _data.oracleAggregator
        );
}

function _canDoMakerToMakerDebtBridge(DebtBridgeInputData memory _data)
    view
    returns (bool)
{
    uint256 maxBorToMakerPos =
        _getMaxAmtToBorrow(
            _data.debtAmt,
            _getGasCostMakerToMaker(
                _data.makerDestVaultId == 0,
                _data.flashRoute
            ),
            _data.fees,
            _data.oracleAggregator
        );
    return
        !_isDebtAmtDust(
            _data.dsa,
            _data.makerDestVaultId,
            _data.makerDestColType,
            maxBorToMakerPos
        ) &&
        !_isDebtCeilingReached(
            _data.dsa,
            _data.makerDestVaultId,
            _data.makerDestColType,
            maxBorToMakerPos
        ) &&
        _destVaultWillBeSafe(
            _data.dsa,
            _data.makerDestVaultId,
            _data.makerDestColType,
            _data.colAmt,
            maxBorToMakerPos
        );
}

function _canDoMakerToCompoundDebtBridge(DebtBridgeInputData memory _data)
    view
    returns (bool)
{
    uint256 maxBorToCompPos =
        _getMaxAmtToBorrow(
            _data.debtAmt,
            _getGasCostMakerToCompound(_data.flashRoute),
            _data.fees,
            _data.oracleAggregator
        );

    return
        _cTokenHasLiquidity(
            DAI,
            _data.flashRoute == 2
                ? _data.debtAmt + maxBorToCompPos
                : maxBorToCompPos
        ) &&
        _compoundPositionWillBeSafe(
            _data.dsa,
            _data.colToken,
            _data.colAmt,
            DAI,
            maxBorToCompPos
        );
}

