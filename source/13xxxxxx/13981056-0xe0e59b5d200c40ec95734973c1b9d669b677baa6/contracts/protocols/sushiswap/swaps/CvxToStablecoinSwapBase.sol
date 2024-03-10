// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SwapBase} from "./SwapBase.sol";

abstract contract CvxToStablecoinSwapBase is SwapBase {
    IERC20 private constant _CVX =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 private constant _WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor(IERC20 stablecoin) public SwapBase(_CVX, stablecoin) {} // solhint-disable-line no-empty-blocks

    function _getPath()
        internal
        view
        virtual
        override
        returns (address[] memory)
    {
        address[] memory path = new address[](3);

        path[0] = address(_CVX);
        path[1] = address(_WETH);
        path[2] = address(_OUT_TOKEN);

        return path;
    }
}

