// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {CrvToStablecoinSwapBase} from "./CrvToStablecoinSwapBase.sol";

contract CrvToDaiSwap is CrvToStablecoinSwapBase {
    string public constant override NAME = "crv-to-dai";

    IERC20 private constant _DAI =
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    // solhint-disable-next-line no-empty-blocks
    constructor() public CrvToStablecoinSwapBase(_DAI) {}
}

