// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    GelatoConditionsStandard
} from "@gelatonetwork/core/contracts/gelato_conditions/GelatoConditionsStandard.sol";
import {
    _compoundPositionWillBeSafe
} from "../../../../functions/gelato/conditions/compound/FCompoundPositionWillBeSafe.sol";
import {DAI} from "../../../../constants/CTokens.sol";
import {
    _getMakerVaultCollateralBalance
} from "../../../../functions/dapps/FMaker.sol";
import {
    _getMaxAmtToBorrowMakerToCompound
} from "../../../../functions/gelato/FGelatoDebtBridge.sol";
import {
    IInstaFeeCollector
} from "../../../../interfaces/InstaDapp/IInstaFeeCollector.sol";

contract ConditionMakerToCompoundSafe is GelatoConditionsStandard {
    address public immutable instaFeeCollector;
    address public immutable oracleAggregator;

    constructor(address _instaFeeCollector, address _oracleAggregator) {
        instaFeeCollector = _instaFeeCollector;
        oracleAggregator = _oracleAggregator;
    }

    function getConditionData(address _dsa, uint256 _fromVaultId)
        public
        pure
        virtual
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                this.compoundPositionWillBeSafe.selector,
                _dsa,
                _fromVaultId
            );
    }

    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        (address _dsa, uint256 _fromVaultId) =
            abi.decode(_conditionData[4:], (address, uint256));

        return compoundPositionWillBeSafe(_dsa, _fromVaultId);
    }

    function compoundPositionWillBeSafe(address _dsa, uint256 _fromVaultId)
        public
        view
        returns (string memory)
    {
        return
            _compoundPositionWillBeSafe(
                _dsa,
                _getMakerVaultCollateralBalance(_fromVaultId),
                DAI,
                _getMaxAmtToBorrowMakerToCompound(
                    _fromVaultId,
                    IInstaFeeCollector(instaFeeCollector).fee(),
                    oracleAggregator
                )
            )
                ? OK
                : "CompoundPositionsWillNotBeSafe";
    }
}

