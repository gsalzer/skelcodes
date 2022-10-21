// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {Address} from "contracts/libraries/Imports.sol";
import {ProxyFactoryV2} from "./ProxyFactoryV2.sol";
import {AddressRegistryV2} from "contracts/registry/AddressRegistryV2.sol";
import {UpgradeableContractFactory} from "./UpgradeableContractFactory.sol";

contract AddressRegistryV2FactoryV2 is UpgradeableContractFactory {
    using Address for address;

    function create(
        address proxyFactory,
        address proxyAdmin,
        bytes memory initData
    ) public override returns (address) {
        address logic = _deployLogic(initData);
        address proxy =
            ProxyFactoryV2(proxyFactory).createAndTransfer(
                logic,
                proxyAdmin,
                initData,
                msg.sender
            );
        return proxy;
    }

    function _deployLogic(bytes memory initData)
        internal
        virtual
        override
        returns (address)
    {
        AddressRegistryV2 logic = new AddressRegistryV2();
        address _logic = address(logic);
        _logic.functionCall(initData);
        return _logic;
    }
}

