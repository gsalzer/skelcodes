// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {CrvToStablecoinSwapBase} from "./CrvToStablecoinSwapBase.sol";

contract CrvToUsdcSwap is CrvToStablecoinSwapBase {
    string public constant override NAME = "crv-to-usdc";

    IERC20 private constant _USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // solhint-disable-next-line no-empty-blocks
    constructor() public CrvToStablecoinSwapBase(_USDC) {}
}

