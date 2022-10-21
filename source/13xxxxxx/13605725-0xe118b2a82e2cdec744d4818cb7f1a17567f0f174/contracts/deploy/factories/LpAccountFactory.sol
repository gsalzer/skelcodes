// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {Address} from "contracts/libraries/Imports.sol";
import {LpAccount} from "contracts/lpaccount/LpAccount.sol";
import {UpgradeableContractFactory} from "./UpgradeableContractFactory.sol";

contract LpAccountFactory is UpgradeableContractFactory {
    using Address for address;

    function _deployLogic(bytes memory initData)
        internal
        virtual
        override
        returns (address)
    {
        LpAccount logic = new LpAccount();
        address _logic = address(logic);
        _logic.functionCall(initData);
        return _logic;
    }
}

