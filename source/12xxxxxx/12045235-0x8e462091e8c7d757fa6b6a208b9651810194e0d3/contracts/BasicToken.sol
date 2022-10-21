// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.5.16;

import "openzeppelin-solidity-2.3.0/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity-2.3.0/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity-2.3.0/contracts/token/ERC20/ERC20Pausable.sol";

contract TestERC20 is ERC20Detailed, ERC20Mintable, ERC20Pausable {
    constructor(uint amount) ERC20Detailed('StonkBase SBF PreFarm 31 March 2021', 'SBF-MAR21', 18) public {
        mint(msg.sender, amount);
    }

}
