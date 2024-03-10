// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract DREAM is ERC20PresetMinterPauser {
  constructor(uint256 _initialSupply) public ERC20PresetMinterPauser("DREAM", "DREAM") {
    _mint(msg.sender, _initialSupply);
  }
}

