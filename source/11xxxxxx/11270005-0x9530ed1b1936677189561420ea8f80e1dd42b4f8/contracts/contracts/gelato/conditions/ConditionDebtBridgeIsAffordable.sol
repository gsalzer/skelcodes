// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import {
    GelatoConditionsStandard
} from "@gelatonetwork/core/contracts/conditions/GelatoConditionsStandard.sol";
import {
    IGelatoCore
} from "@gelatonetwork/core/contracts/gelato_core/interfaces/IGelatoCore.sol";
import {GelatoBytes} from "../../../lib/GelatoBytes.sol";
import {
    _getMakerVaultDebt,
    _getMakerVaultCollateralBalance
} from "../../../functions/dapps/FMaker.sol";
import {
    _getFlashLoanRoute,
    _getGasCostMakerToMaker,
    _getRealisedDebt
} from "../../../functions/gelato/FGelatoDebtBridge.sol";
import {_getGelatoProviderFees} from "../../../functions/gelato/FGelato.sol";
import {DAI} from "../../../constants/CInstaDapp.sol";
import {wdiv} from "../../../vendor/DSMath.sol";

/// @title ConditionDebtBridgeIsAffordable
/// @notice Condition checking if Debt Refinance is affordable.
/// @author Gelato Team
contract ConditionDebtBridgeIsAffordable is GelatoConditionsStandard {
    using GelatoBytes for bytes;

    /// @notice Convenience function for off-chain _conditionData encoding
    /// @dev Use the return for your Task's Condition.data field off-chain.
    /// @dev WARNING _ratioLimit should be in wad standard.
    /// @return The encoded payload for your Task's Condition.data field.
    function getConditionData(uint256 _vaultId, uint256 _ratioLimit)
        public
        pure
        virtual
        returns (bytes memory)
    {
        return abi.encode(_vaultId, _ratioLimit);
    }

    /// @notice Standard GelatoCore system function
    /// @dev A standard interface for GelatoCore to read Conditions
    /// @param _conditionData The data you get from `getConditionData()`
    /// @return OK if the Condition is there, else some error message.
    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        (uint256 _vaultID, uint256 _ratioLimit) = abi.decode(
            _conditionData,
            (uint256, uint256)
        );

        return isAffordable(_vaultID, _ratioLimit);
    }

    /// @notice Specific implementation of this Condition's ok function
    /// @dev Check if the debt refinancing action is affordable.
    /// @dev WARNING _ratioLimit should be in wad standard.
    /// @param _vaultId The id of the Maker vault
    /// @param _ratioLimit the maximum limit define by the user up on which
    /// the debt is too expensive for him
    /// @return OK if the Debt Bridge is affordable, otherwise some error message.
    function isAffordable(uint256 _vaultId, uint256 _ratioLimit)
        public
        view
        returns (string memory)
    {
        uint256 wColToWithdrawFromMaker = _getMakerVaultCollateralBalance(
            _vaultId
        );
        uint256 gasFeesPaidFromCol = _getGelatoProviderFees(
            _getGasCostMakerToMaker(
                true,
                _getFlashLoanRoute(
                    DAI,
                    _getRealisedDebt(_getMakerVaultDebt(_vaultId))
                )
            )
        );
        if (wdiv(gasFeesPaidFromCol, wColToWithdrawFromMaker) >= _ratioLimit)
            return "DebtBridgeNotAffordable";
        return OK;
    }
}

