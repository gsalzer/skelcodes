// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import {
    GelatoConditionsStandard
} from "@gelatonetwork/core/contracts/conditions/GelatoConditionsStandard.sol";
import {
    _getMakerVaultDebt,
    _getMakerVaultCollateralBalance,
    _vaultWillBeSafe,
    _newVaultWillBeSafe,
    _isVaultOwner
} from "../../../functions/dapps/FMaker.sol";
import {DAI} from "../../../constants/CInstaDapp.sol";
import {
    _getFlashLoanRoute,
    _getGasCostMakerToMaker,
    _getRealisedDebt
} from "../../../functions/gelato/FGelatoDebtBridge.sol";
import {_getGelatoExecutorFees} from "../../../functions/gelato/FGelato.sol";
import {GelatoBytes} from "../../../lib/GelatoBytes.sol";
import {sub} from "../../../vendor/DSMath.sol";

contract ConditionDestVaultWillBeSafe is GelatoConditionsStandard {
    using GelatoBytes for bytes;

    function getConditionData(
        address _dsa,
        uint256 _fromVaultId,
        uint256 _destVaultId,
        string calldata _destColType
    ) public pure virtual returns (bytes memory) {
        return
            abi.encodeWithSelector(
                this.destVaultWillBeSafe.selector,
                _dsa,
                _fromVaultId,
                _destVaultId,
                _destColType
            );
    }

    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        (
            address _dsa,
            uint256 _fromVaultId,
            uint256 _destVaultId,
            string memory _destColType
        ) = abi.decode(_conditionData[4:], (address, uint256, uint256, string));

        return
            destVaultWillBeSafe(_dsa, _fromVaultId, _destVaultId, _destColType);
    }

    function destVaultWillBeSafe(
        address _dsa,
        uint256 _fromVaultId,
        uint256 _destVaultId,
        string memory _destColType
    ) public view returns (string memory) {
        _destVaultId = _isVaultOwner(_destVaultId, _dsa) ? _destVaultId : 0;
        uint256 wDaiToBorrow =
            _getRealisedDebt(_getMakerVaultDebt(_fromVaultId));
        uint256 wColToDeposit =
            sub(
                _getMakerVaultCollateralBalance(_fromVaultId),
                _getGelatoExecutorFees(
                    _getGasCostMakerToMaker(
                        _destVaultId == 0,
                        _getFlashLoanRoute(DAI, wDaiToBorrow)
                    )
                )
            );

        return
            destVaultWillBeSafeExplicit(
                _destVaultId,
                wDaiToBorrow,
                wColToDeposit,
                _destColType
            )
                ? OK
                : "DestVaultWillNotBeSafe";
    }

    function destVaultWillBeSafeExplicit(
        uint256 _vaultId,
        uint256 _wDaiToBorrow,
        uint256 _wColToDeposit,
        string memory _colType
    ) public view returns (bool) {
        return
            _vaultId == 0
                ? _newVaultWillBeSafe(_colType, _wDaiToBorrow, _wColToDeposit)
                : _vaultWillBeSafe(_vaultId, _wDaiToBorrow, _wColToDeposit);
    }
}

