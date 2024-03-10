// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract Rubix is ERC20Snapshot, Pausable {
    constructor() public ERC20("Rubix", "RBX") {
        _mint(msg.sender, 10000000 * 10 ** uint(decimals()));
    }
}
