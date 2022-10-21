//SPDX-License-Identifier: Unlicense
pragma solidity =0.6.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract GLDToken is ERC20Upgradeable {
    function initialize() initializer external {
      require(msg.sender == address(0x65E0B1BF877e0175A76d121FB8C4E180d8E20835));
      ERC20Upgradeable.__ERC20_init("INDIGO", "indigo.loans");
      _mint(msg.sender, 255 * 1e18);
    }
}
