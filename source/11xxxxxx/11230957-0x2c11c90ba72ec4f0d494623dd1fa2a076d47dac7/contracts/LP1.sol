// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract LP1 is ERC20PresetMinterPauser {
    // Cap at 1 million

    constructor() public ERC20PresetMinterPauser("lp1", "lp1") {}
}

