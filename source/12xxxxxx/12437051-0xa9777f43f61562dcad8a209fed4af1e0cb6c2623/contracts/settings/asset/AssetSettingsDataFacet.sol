// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { RolesMods } from "../../contexts2/access-control/roles/RolesMods.sol";
import { ADMIN, AUTHORIZED } from "../../shared/roles.sol";

// Interfaces
import { ICErc20 } from "../../shared/interfaces/ICErc20.sol";

// Libraries
import {
    CacheLib,
    Cache,
    CacheType
} from "../../shared/libraries/CacheLib.sol";
import { AssetCTokenLib } from "./libraries/AssetCTokenLib.sol";
import { MaxLoanAmountLib } from "./libraries/MaxLoanAmountLib.sol";
import { MaxTVLLib } from "./libraries/MaxTVLLib.sol";

// Storage
import { AppStorageLib, AppStorage } from "../../storage/app.sol";

/**
 * @notice View function to get asset setting values.
 *
 * @author develop@teller.finance
 */
contract AssetSettingsDataFacet {
    function getAssetMaxLoanAmount(address asset)
        external
        view
        returns (uint256)
    {
        return MaxLoanAmountLib.get(asset);
    }

    function getAssetMaxTVL(address asset) external view returns (uint256) {
        return MaxTVLLib.get(asset);
    }

    function getAssetCToken(address asset) external view returns (ICErc20) {
        return AssetCTokenLib.get(asset);
    }
}

