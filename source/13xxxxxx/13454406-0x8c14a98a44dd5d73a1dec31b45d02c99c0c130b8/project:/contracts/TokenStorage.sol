pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

import './ITokenStorage.sol';

contract TokenStorage is ITokenStorage, Ownable {
    using SafeERC20 for IERC20;

    function transfer(IERC20 token, address to, uint256 amount) public onlyOwner {
        require (token.balanceOf(address(this)) >= amount, "insufficient reserved token balance");
        token.safeTransfer(to, amount);
    }

    function burn(ERC20Burnable token, uint256 amount) public onlyOwner {
        require (token.balanceOf(address(this)) >= amount, "insufficient reserved token balance");
        token.burn(amount);
    }
}

