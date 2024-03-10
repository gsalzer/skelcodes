pragma solidity ^0.5.12;

import { Ownable } from "node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import { ERC20 } from "node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

import { SeigManagerI } from "stake/interfaces/SeigManagerI.sol";

import { ERC165Checker } from "node_modules/openzeppelin-solidity/contracts/introspection/ERC165Checker.sol";

import { ERC20OnApprove } from "stake/tokens/ERC20OnApprove.sol";
import { AuthController } from "stake/tokens/AuthController.sol";

contract SeigToken is ERC20, Ownable, ERC20OnApprove, AuthController {
  SeigManagerI public seigManager;

  function setSeigManager(SeigManagerI _seigManager) external onlyOwner {
    seigManager = _seigManager;
  }

  //////////////////////
  // Override ERC20 functions
  //////////////////////

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(msg.sender == sender || msg.sender == recipient, "SeigToken: only sender or recipient can transfer");
    super._transfer(sender, recipient, amount);
    if (address(seigManager) != address(0)) {
      // seigManager.onTransfer(sender, recipient, amount);
    }
  }

  function _mint(address account, uint256 amount) internal {
    super._mint(account, amount);
    if (address(seigManager) != address(0)) {
      // seigManager.onTransfer(address(0), account, amount);
    }
  }

  function _burn(address account, uint256 amount) internal {
    super._burn(account, amount);
    if (address(seigManager) != address(0)) {
      // seigManager.onTransfer(account, address(0), amount);
    }
  }
}
