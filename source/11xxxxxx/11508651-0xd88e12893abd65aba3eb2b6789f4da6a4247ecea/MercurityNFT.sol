//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./ERC1155Tradable.sol";

/**
 * @title MercurityNFT
 * @dev Mercurity NFT
 */
contract MercurityNFT is ERC1155Tradable {
    //  * @param _proxyRegistryAddress The address of the OpenSea/Wyvern proxy registry
    //  *                              On mainnet: "0xa5409ec958c83c3f309868babaca7c86dcb077c1"
    constructor(address _proxyRegistryAddress) public ERC1155Tradable("MercurityNFT", "MERNFT", _proxyRegistryAddress) {
		  _setBaseMetadataURI("https://nft.mercurity.finance/");
	  }
  
    function contractURI() public pure returns (string memory) {
		  return "https://nft.mercurity.finance/Mercurity.json";
	  }

}
