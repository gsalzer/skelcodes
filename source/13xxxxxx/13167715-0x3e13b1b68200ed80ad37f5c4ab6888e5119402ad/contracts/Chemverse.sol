// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
 
import "https://github.com/0xcert/ethereum-erc721/src/contracts/tokens/nf-token-metadata.sol";
import "https://github.com/0xcert/ethereum-erc721/src/contracts/ownership/ownable.sol";
 
contract Chemverse is NFTokenMetadata, Ownable {
 
  constructor() {
    nftName = "Chemverse Compounds";
    nftSymbol = "CMVC";
  }
  

  function claim(address _to, uint256 _tokenId) public {
    require(_tokenId >= 0, "Token ID invalid");
    require(_tokenId < 16384, "Token ID invalid");

    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, string(abi.encodePacked("https://www.chemverse.xyz/api/compound/", toString(_tokenId))));
  }
  
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
  
}
