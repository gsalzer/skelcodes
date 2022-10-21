// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenERC20 is ERC20('Mixsome', 'SOME') {
    constructor () {
        _mint(msg.sender, 93777508090614882400000000);
    }
}
