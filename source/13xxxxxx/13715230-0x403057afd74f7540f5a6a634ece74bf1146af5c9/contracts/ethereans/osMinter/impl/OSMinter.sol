// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../model/IOSMinter.sol";
import "../../../core/model/IOrganization.sol";
import "@ethereansos/swissknife/contracts/generic/impl/LazyInitCapableElement.sol";
import "@ethereansos/items-v2/contracts/projection/IItemProjection.sol";
import "@ethereansos/items-v2/contracts/model/IItemInteroperableInterface.sol";
import { ComponentsGrimoire } from "../../lib/KnowledgeBase.sol";
import { AddressUtilities, Uint256Utilities } from "@ethereansos/swissknife/contracts/lib/GeneralUtilities.sol";

contract OSMinter is IOSMinter, LazyInitCapableElement {
    using AddressUtilities for address;
    using Uint256Utilities for uint256;

    address private _projectionAddress;
    uint256 private _itemId;
    bytes32 private _collectionId;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory) {
        address itemAddress;
        (_projectionAddress, itemAddress) = abi.decode(lazyInitData, (address, address));
        _collectionId = IItemProjection(_projectionAddress).collectionId();
        _itemId = IItemInteroperableInterface(itemAddress).itemId();
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IOSMinter).interfaceId ||
            interfaceId == this.mint.selector;
    }

    function mint(uint256 value, address receiver) external override {
        require(msg.sender == IOrganization(host).get(ComponentsGrimoire.COMPONENT_KEY_TOKEN_MINTER_AUTH), "unauthorized");
        CreateItem[] memory createItems = new CreateItem[](1);
        createItems[0] = CreateItem(
            Header(address(0), "", "", ""),
            _collectionId,
            _itemId,
            receiver.asSingletonArray(),
            value.asSingletonArray()
        );
        IItemProjection(_projectionAddress).mintItems(createItems);
    }
}
