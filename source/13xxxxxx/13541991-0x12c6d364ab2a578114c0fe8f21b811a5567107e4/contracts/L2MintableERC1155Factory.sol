// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./thirdparty/erc1167/CloneFactory.sol";

import "./L2MintableERC1155.sol";

contract L2MintableERC1155Factory is CloneFactory {
    event InstanceCreatedEvent(L2MintableERC1155 instance);

    address immutable implementation;
    L2MintableERC1155[] public instances;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function create(
        address owner,
        address authorization,
        string memory name
    ) external {
        L2MintableERC1155 instance = L2MintableERC1155(
            createClone(implementation)
        );
        instance.init(owner, authorization, name);
        instances.push(instance);
        InstanceCreatedEvent(instance);
    }

    function getInstances() external view returns (L2MintableERC1155[] memory) {
        return instances;
    }
}

