// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {ProxyFactory} from "./ProxyFactory.sol";

abstract contract UpgradeableContractFactory {
    function create(
        address proxyFactory,
        address proxyAdmin,
        bytes memory initData
    ) public virtual returns (address) {
        address logic = _deployLogic(initData);
        address proxy =
            ProxyFactory(proxyFactory).create(logic, proxyAdmin, initData);
        return address(proxy);
    }

    /**
     * `initData` is passed to allow initialization of the logic
     * contract's storage.  This is to block possible attack vectors.
     * Future added functionality may allow those controlling the
     * contract to selfdestruct it.
     */
    function _deployLogic(bytes memory initData)
        internal
        virtual
        returns (address);
}

