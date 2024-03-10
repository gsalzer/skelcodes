// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import { ERC1155PresetMinterPauser } from "@openzeppelin/contracts/presets/ERC1155PresetMinterPauser.sol";

contract NFT is ERC1155PresetMinterPauser {
  constructor(string memory uri) ERC1155PresetMinterPauser(uri) {}
}
