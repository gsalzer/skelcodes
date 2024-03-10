// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import {AccessControlMixin} from "../matic/AccessControlMixin.sol";
import {NativeMetaTransaction} from "../matic/NativeMetaTransaction.sol";
import {ContextMixin} from "../matic/ContextMixin.sol";

abstract contract ERC721MetaTransaction is 
    ERC721,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin
{
    constructor(string memory _name) {
        _setupContractId("ERC721MetaTransaction"); //for errorMessage
        _initializeEIP712(_name);
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        virtual
        internal
        override
        view
        returns (address)
    {
        return ContextMixin.msgSender();
    }
}

