pragma solidity ^0.6.0;

import "ERC20.sol";
import "MinterRole.sol";

contract ZHToken is ERC20, MinterRole {

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
    
    function burn(uint256 amount) public onlyMinter returns (bool) {
        _burn(_msgSender(), amount);
    }

}
