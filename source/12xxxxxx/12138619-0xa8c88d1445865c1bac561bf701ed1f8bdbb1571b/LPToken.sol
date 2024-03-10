// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.5.17;

import "./ERC20.sol";


contract LPToken is ERC20 {
    string public constant name     = "DEXG Liquidity Pool";
    string public constant symbol   = "DEXG-LP";
    uint8  public constant decimals = 18;
}
