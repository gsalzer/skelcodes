// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "./interfaces/I1MIL.sol";

contract MIL1 is I1MIL, ERC20PresetMinterPauser {

uint public constant override INITIAL_SUPPLY = 1_000_000 * DECIMAL_MULTIPLIER;
uint public constant override MAX_SUPPLY = 10_000_000 * DECIMAL_MULTIPLIER;
uint private constant DECIMAL_MULTIPLIER = 10**18;

constructor() ERC20PresetMinterPauser("1MILNFT", "1MIL")  {
_mint(msg.sender, INITIAL_SUPPLY);
}

function _mint(address account, uint amount) internal virtual override {
require(totalSupply() + (amount) <= MAX_SUPPLY, "1MIL: MAX_SUPPLY");
super._mint(account, amount);
}
}

