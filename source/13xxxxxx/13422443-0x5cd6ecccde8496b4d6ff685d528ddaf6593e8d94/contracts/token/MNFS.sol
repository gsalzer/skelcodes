// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../openzeppelin/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract ERC20MANIFEST is ERC20PresetMinterPauser {
    constructor () ERC20PresetMinterPauser("Manifest", "MNFS") {
        _mint(msg.sender, 10e32);
    }
}
