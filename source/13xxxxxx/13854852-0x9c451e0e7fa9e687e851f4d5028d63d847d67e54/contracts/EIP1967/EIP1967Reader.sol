// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * Implements http://eips.ethereum.org/EIPS/eip-1967: proxy implementation address
 * is stored in pseudo random storage slot id.
 */
abstract contract EIP1967Reader {
    /**
     * Storage slot id used to store the address of the current implementation
     * contract (see `EIP1967Writer._setImplementation()`)
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    /**
     * Encoded `initialize()` function call, which is used by `EIP1967Writer`
     * to call the implementation's `initialize()` method immediately after upgrade
     * (see `EIP1967Writer._initializeImplementation()`)
     */
    bytes4 internal constant _INITIALIZE_CALL =
        bytes4(keccak256("initialize()"));

    /**
     * Returns the current implementation address read from the storage slot
     */
    function _implementationAddress() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

