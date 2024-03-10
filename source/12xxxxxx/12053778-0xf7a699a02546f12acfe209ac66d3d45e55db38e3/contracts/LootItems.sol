// SPDX-License-Identifier: WTFPL
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ERC1155/ERC1155Tradable.sol";

contract LootItems is ERC1155Tradable {
    /**
     * @dev Initialize the LOOT Items
     */
    constructor(string memory baseURI, address proxyRegistryAddress)
        public
        ERC1155Tradable("LootItems", "LIT", proxyRegistryAddress)
    {
        super._setBaseMetadataURI(baseURI);
    }
}

