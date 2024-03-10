// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {AaveToStablecoinSwapBase} from "./AaveToStablecoinSwapBase.sol";

contract AaveToDaiSwap is AaveToStablecoinSwapBase {
    string public constant override NAME = "aave-to-dai";

    IERC20 private constant _DAI =
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    // solhint-disable-next-line no-empty-blocks
    constructor() public AaveToStablecoinSwapBase(_DAI) {}
}

