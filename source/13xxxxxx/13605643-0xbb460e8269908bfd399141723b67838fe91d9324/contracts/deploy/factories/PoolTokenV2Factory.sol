// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {Address} from "contracts/libraries/Imports.sol";
import {PoolTokenV2} from "contracts/pool/PoolTokenV2.sol";

contract PoolTokenV2Factory {
    using Address for address;

    address private _logic;

    /**
     * `initData` is passed to allow initialization of the logic
     * contract's storage.  This is to block possible attack vectors.
     * Future added functionality may allow those controlling the
     * contract to selfdestruct it.
     */
    function create(bytes memory initData) external returns (address) {
        if (_logic != address(0)) {
            return _logic;
        }
        PoolTokenV2 logic = new PoolTokenV2();
        _logic = address(logic);
        _logic.functionCall(initData);
        return _logic;
    }
}

