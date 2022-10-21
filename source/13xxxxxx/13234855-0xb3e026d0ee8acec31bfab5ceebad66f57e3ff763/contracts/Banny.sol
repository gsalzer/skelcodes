// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@paulrberg/contracts/token/erc20/Erc20Permit.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Banny is ERC20, ERC20Permit, Ownable {
    constructor() ERC20("Banny", "BANNY") ERC20Permit("Banny") {}

    function mint(address _account, uint256 _amount) external onlyOwner {
        return _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlyOwner {
        return _burn(_account, _amount);
    }
}

