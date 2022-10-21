// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {Address} from "contracts/libraries/Imports.sol";
import {MetaPoolToken} from "contracts/mapt/MetaPoolToken.sol";
import {UpgradeableContractFactory} from "./UpgradeableContractFactory.sol";

contract MetaPoolTokenFactory is UpgradeableContractFactory {
    using Address for address;

    function _deployLogic(bytes memory initData)
        internal
        virtual
        override
        returns (address)
    {
        MetaPoolToken logic = new MetaPoolToken();
        address _logic = address(logic);
        _logic.functionCall(initData);
        return _logic;
    }
}

