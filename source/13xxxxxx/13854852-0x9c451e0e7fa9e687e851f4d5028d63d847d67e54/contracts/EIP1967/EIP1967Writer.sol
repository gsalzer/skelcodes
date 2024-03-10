// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

import "./EIP1967Reader.sol";

/**
 * Implements http://eips.ethereum.org/EIPS/eip-1967: proxy implementation address
 * is stored in pseudo random storage slot id.
 */
abstract contract EIP1967Writer is EIP1967Reader {
    /**
     * Emitted when the implementation is upgraded.
     */
    event Upgraded(address implementation);

    /**
     * Performs implementation upgrade and immediately initializes it by calling
     * the new implementation's `initialize()` method.
     *
     * Emits an `Upgraded` event after.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        _initializeImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(
            Address.isContract(newImplementation),
            "implementation is not a contract"
        );
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    /**
     * Initializes the new implementation by calling its `initialize()` method.
     */
    function _initializeImplementation(address newImplementation) private {
        bytes memory data = abi.encodePacked(_INITIALIZE_CALL);
        Address.functionDelegateCall(newImplementation, data);
    }
}

