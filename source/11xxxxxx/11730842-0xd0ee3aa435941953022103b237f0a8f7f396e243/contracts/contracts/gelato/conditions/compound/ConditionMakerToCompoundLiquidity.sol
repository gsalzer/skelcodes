// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    GelatoConditionsStandard
} from "@gelatonetwork/core/contracts/gelato_conditions/GelatoConditionsStandard.sol";
import {DAI} from "../../../../constants/CTokens.sol";
import {
    _cTokenHasLiquidity
} from "../../../../functions/gelato/conditions/compound/FCompoundHasLiquidity.sol";
import {
    _getMaxAmtToBorrowMakerToCompound
} from "../../../../functions/gelato/FGelatoDebtBridge.sol";
import {
    IInstaFeeCollector
} from "../../../../interfaces/InstaDapp/IInstaFeeCollector.sol";

contract ConditionMakerToCompoundLiquid is GelatoConditionsStandard {
    address public immutable instaFeeCollector;
    address public immutable oracleAggregator;

    constructor(address _instaFeeCollector, address _oracleAggregator) {
        instaFeeCollector = _instaFeeCollector;
        oracleAggregator = _oracleAggregator;
    }

    function getConditionData(uint256 _fromVaultId)
        public
        pure
        virtual
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                this.cTokenHasLiquidity.selector,
                _fromVaultId
            );
    }

    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        uint256 _fromVaultId = abi.decode(_conditionData[4:], (uint256));

        return cTokenHasLiquidity(_fromVaultId);
    }

    function cTokenHasLiquidity(uint256 _fromVaultId)
        public
        view
        returns (string memory)
    {
        return
            _cTokenHasLiquidity(
                DAI,
                _getMaxAmtToBorrowMakerToCompound(
                    _fromVaultId,
                    IInstaFeeCollector(instaFeeCollector).fee(),
                    oracleAggregator
                )
            )
                ? OK
                : "CompoundHasNotEnoughLiquidity";
    }
}

