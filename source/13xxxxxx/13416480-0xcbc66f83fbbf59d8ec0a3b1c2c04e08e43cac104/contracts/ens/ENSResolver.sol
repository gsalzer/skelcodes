// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Resolver} from "./resolvers/Resolver.sol";
import {AddressResolver} from "./resolvers/AddressResolver.sol";
import {NameResolver} from "./resolvers/NameResolver.sol";

contract ENSResolver is
    Ownable,
    AddressResolver,
    NameResolver
{
    constructor() {}

    function setAddr(
        bytes32 node,
        address _addr
    )
        external
        onlyOwner
    {
        _setAddr(node, _addr);
    }

    function setName(
        bytes32 node,
        string calldata _name
    )
        external
        onlyOwner
    {
        _setName(node, _name);
    }
}

