/**

  Source code of Opium Protocol
  Web https://opium.network
  Telegram https://t.me/opium_network
  Twitter https://twitter.com/opium_network

 */

// File: LICENSE

/**

The software and documentation available in this repository (the "Software") is protected by copyright law and accessible pursuant to the license set forth below. Copyright © 2020 Blockeys BV. All rights reserved.

Permission is hereby granted, free of charge, to any person or organization obtaining the Software (the “Licensee”) to privately study, review, and analyze the Software. Licensee shall not use the Software for any other purpose. Licensee shall not modify, transfer, assign, share, or sub-license the Software or any derivative works of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


// File: erc721o/contracts/Libs/LibPosition.sol

pragma solidity ^0.5.4;

library LibPosition {
  function getLongTokenId(bytes32 _hash) public pure returns (uint256 tokenId) {
    tokenId = uint256(keccak256(abi.encodePacked(_hash, "LONG")));
  }

  function getShortTokenId(bytes32 _hash) public pure returns (uint256 tokenId) {
    tokenId = uint256(keccak256(abi.encodePacked(_hash, "SHORT")));
  }
}
