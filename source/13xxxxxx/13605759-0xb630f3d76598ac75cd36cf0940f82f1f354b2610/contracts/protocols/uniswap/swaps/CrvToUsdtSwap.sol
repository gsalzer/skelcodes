// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {CrvToStablecoinSwapBase} from "./CrvToStablecoinSwapBase.sol";

contract CrvToUsdtSwap is CrvToStablecoinSwapBase {
    string public constant override NAME = "crv-to-usdt";

    IERC20 private constant _USDT =
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    // solhint-disable-next-line no-empty-blocks
    constructor() public CrvToStablecoinSwapBase(_USDT) {}
}

