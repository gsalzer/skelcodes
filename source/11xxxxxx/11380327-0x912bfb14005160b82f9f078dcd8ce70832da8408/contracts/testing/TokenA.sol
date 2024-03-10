//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract TokenA is ERC20PresetMinterPauser {
    constructor() public ERC20PresetMinterPauser("TokenA", "TA") {

    }
}
