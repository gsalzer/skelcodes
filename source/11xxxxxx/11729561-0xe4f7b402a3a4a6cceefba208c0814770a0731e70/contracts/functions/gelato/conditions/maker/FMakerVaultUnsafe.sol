// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {wmul, wdiv} from "../../../../vendor/DSMath.sol";
import {
    IInstaMakerResolver
} from "../../../../interfaces/InstaDapp/resolvers/IInstaMakerResolver.sol";
import {GelatoBytes} from "../../../../lib/GelatoBytes.sol";
import {INSTA_MAKER_RESOLVER} from "../../../../constants/CInstaDapp.sol";

function _isVaultUnsafe(
    uint256 _vaultId,
    address _priceOracle,
    bytes memory _oraclePayload,
    uint256 _minColRatio
) view returns (bool) {
    (bool success, bytes memory returndata) =
        _priceOracle.staticcall(_oraclePayload);

    if (!success) {
        GelatoBytes.revertWithError(
            returndata,
            "ConditionMakerVaultUnsafe.isVaultUnsafe:oracle:"
        );
    }

    uint256 colPrice = abi.decode(returndata, (uint256));

    IInstaMakerResolver.VaultData memory vault =
        IInstaMakerResolver(INSTA_MAKER_RESOLVER).getVaultById(_vaultId);

    uint256 colRatio = wdiv(wmul(vault.collateral, colPrice), vault.debt);

    return colRatio < _minColRatio;
}

