// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {PoolTokenV2} from "./PoolTokenV2.sol";

/** @dev dummy contract using storage slots */
contract ExtraStorage {
    // The `_notEntered` bool slot used by the re-entrancy guard
    // must be `true` to allow `initializeUpgrade` to be called
    // during the upgrade.  This is slot 151 on the original
    // logic contract.
    //
    // By shifting the storage by 105, the slot used by this logic
    // contract's re-entrancy guard will be 151 + 105 = 256.  This
    // is the slot used by `_decimals`, which is a non-zero uint8.
    uint256[105] private _gap;
}

/**
 * @dev Test contract to bork upgrade. Using `ExtraStorage` at the
 * base level means the PoolTokenV2 storage slots are shifted.
 *
 * Should not be used other than in test files!
 */
// solhint-disable-next-line no-empty-blocks
contract TestBrokenPoolTokenV2 is ExtraStorage, PoolTokenV2 {

}

