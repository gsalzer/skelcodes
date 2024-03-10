// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {BeaconStorage} from "../../lib/upgradable/BeaconStorage.sol";
import {IBeacon} from "../../lib/upgradable/interface/IBeacon.sol";
import {Governable} from "../../lib/Governable.sol";
import {MirrorTokenStorage} from "./MirrorTokenStorage.sol";
import {IMirrorTokenProxy} from "./interface/IMirrorTokenProxy.sol";

/**
 * @title DistributionProxy
 * @author MirrorXYZ
 */
contract MirrorTokenProxy is BeaconStorage, Governable, MirrorTokenStorage {
    constructor(address beacon_, address owner_)
        BeaconStorage(beacon_)
        Governable(owner_)
    {}

    fallback() external payable {
        address logic = IBeacon(beacon).logic();

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), logic, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {}
}

