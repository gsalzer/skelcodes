pragma solidity ^0.5.2;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";

contract RONToken is ERC20, ERC20Detailed,Ownable {
    uint private INITIAL_SUPPLY = 100e26;
    constructor () public ERC20Detailed("RON", "RON", 18) Ownable(){
        _mint(msg.sender, INITIAL_SUPPLY);
    }
    
    function burn(uint256 value) public onlyOwner{
        _burn(msg.sender, value);
    }
}
