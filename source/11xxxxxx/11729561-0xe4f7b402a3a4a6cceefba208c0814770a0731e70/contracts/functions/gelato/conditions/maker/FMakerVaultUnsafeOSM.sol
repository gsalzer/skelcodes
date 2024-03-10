// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {wmul, wdiv} from "../../../../vendor/DSMath.sol";
import {
    IInstaMakerResolver
} from "../../../../interfaces/InstaDapp/resolvers/IInstaMakerResolver.sol";
import {GelatoBytes} from "../../../../lib/GelatoBytes.sol";
import {INSTA_MAKER_RESOLVER} from "../../../../constants/CInstaDapp.sol";

function _isVaultUnsafeOSM(
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
            "FMakerVaultUnsafeOSM._isVaultUnsafeOSM:oracle:"
        );
    }

    (bytes32 colPrice, bool hasNxt) = abi.decode(returndata, (bytes32, bool));

    require(hasNxt, "FMakerVaultUnsafeOSM._isVaultUnsafeOSM: !hasNxt");

    IInstaMakerResolver.VaultData memory vault =
        IInstaMakerResolver(INSTA_MAKER_RESOLVER).getVaultById(_vaultId);

    return
        wdiv(wmul(vault.collateral, uint256(colPrice)), vault.debt) <
        _minColRatio;
}

