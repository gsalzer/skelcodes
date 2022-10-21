// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract Moony20 is ERC20PresetMinterPauser {
    constructor() public ERC20PresetMinterPauser("Moon20", "Moony") {}
}

