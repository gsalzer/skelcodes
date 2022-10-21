// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IConnectDebtBridgeFee
} from "../../../interfaces/InstaDapp/connectors/IConnectDebtBridgeFee.sol";

function _encodeCalculateFee(
    uint256 _amount,
    uint256 _ftf,
    uint256 _fee,
    uint256 _getId,
    uint256 _setId,
    uint256 _setIdFee
) pure returns (bytes memory) {
    return
        abi.encodeWithSelector(
            IConnectDebtBridgeFee.calculateFee.selector,
            _amount,
            _ftf,
            _fee,
            _getId,
            _setId,
            _setIdFee
        );
}

