// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ParagonsDaoVote is Ownable, ERC20("ParagonsDaoVote", "PARA DAO VOTE") {

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        // do nothing
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }


}
