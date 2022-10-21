// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IFurbz is IERC721 {
  function setBaseURI(string memory val) external;
  function setMinter(address val) external;
  function reserve(uint256 amt) external;
  function mint() external returns (uint256);
  function burn(uint256 id) external;
} 
