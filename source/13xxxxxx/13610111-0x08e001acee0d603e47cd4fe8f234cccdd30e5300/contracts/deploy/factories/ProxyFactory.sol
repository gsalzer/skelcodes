// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {TransparentUpgradeableProxy} from "contracts/proxy/Imports.sol";

contract ProxyFactory {
    function create(
        address logic,
        address proxyAdmin,
        bytes memory initData
    ) public returns (address) {
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(logic, proxyAdmin, initData);
        return address(proxy);
    }
}

