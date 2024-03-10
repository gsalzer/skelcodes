// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {ISwapRouter} from "./ISwapRouter.sol";
import {SwapBase} from "./SwapBase.sol";

abstract contract AaveToStablecoinSwapBase is SwapBase {
    IERC20 private constant _AAVE =
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

    IERC20 private constant _WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint24 private _AAVE_WETH_FEE = 3000;
    uint24 private _WETH_STABLECOIN_FEE = 500;

    constructor(IERC20 stablecoin) public SwapBase(_AAVE, stablecoin) {} // solhint-disable-line no-empty-blocks

    function _getPath() internal view virtual override returns (bytes memory) {
        bytes memory path =
            abi.encodePacked(
                address(_IN_TOKEN),
                _AAVE_WETH_FEE,
                address(_WETH),
                _WETH_STABLECOIN_FEE,
                address(_OUT_TOKEN)
            );

        return path;
    }
}

