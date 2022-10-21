// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {Amount} from "../../lib/Amount.sol";

library MozartTypes {

    /* ========== Structs ========== */

    struct Position {
        address owner;
        Amount.Principal collateralAmount;
        Amount.Principal borrowedAmount;
    }

}

