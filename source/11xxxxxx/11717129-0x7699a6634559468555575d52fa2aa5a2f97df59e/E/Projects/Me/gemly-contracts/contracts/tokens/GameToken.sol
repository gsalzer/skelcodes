// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "../access/Governable.sol";

contract GameToken is Governable, ERC20Burnable {
  constructor(address _governance)
    Governable(_governance)
    ERC20("Gemly Game Token", "GMT")
  public {
  }

  function mint(address account, uint256 amount) onlyGameMinter public {
    _mint(account, amount);
  }
}
