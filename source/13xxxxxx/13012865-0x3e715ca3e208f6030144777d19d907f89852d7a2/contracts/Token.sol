// SDPX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20("vibes", "VIBES"), Ownable {
    function mint(uint256 amount_) external onlyOwner {
        _mint(msg.sender, amount_);
    }

    function burn(address account_, uint256 amount_) external onlyOwner {
        _burn(account_, amount_);
    }
}

