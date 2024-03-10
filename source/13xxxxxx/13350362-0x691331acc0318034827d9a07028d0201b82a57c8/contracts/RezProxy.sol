/* SPDX-License-Identifier: BUSL-1.1 */
/* Copyright © 2021 Fragcolor Pte. Ltd. */

pragma solidity ^0.8.7;

import "openzeppelin-solidity/contracts/proxy/Proxy.sol";
import "openzeppelin-solidity/contracts/proxy/utils/Initializable.sol";

contract RezProxy is Proxy {
    bytes32 private constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    bytes32 private constant _INIT_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    function bootstrapProxy(address newImplementation) public {
        bytes32 slot = _INIT_SLOT;
        bool initialized = true;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            initialized := sload(slot)
        }

        require(!initialized, "Already initialized");

        initialized = true;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, initialized)
        }

        require(
            Address.isContract(newImplementation),
            "ERC1967Proxy: new implementation is not a contract"
        );

        slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function _implementation() internal view override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }
}

