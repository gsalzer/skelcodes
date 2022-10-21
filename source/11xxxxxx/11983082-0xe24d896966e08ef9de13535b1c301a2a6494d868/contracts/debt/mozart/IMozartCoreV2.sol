// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {MozartTypes} from "./MozartTypes.sol";

interface IMozartCoreV2 {
    function getPosition(
        uint256 id
    )
        external
        view
        returns (MozartTypes.Position memory);
}

