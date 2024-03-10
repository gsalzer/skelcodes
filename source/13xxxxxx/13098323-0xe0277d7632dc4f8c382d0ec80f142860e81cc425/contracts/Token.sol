pragma solidity ^0.5.15;

import "contracts/ERC20.sol";
import "contracts/Context.sol";
import "contracts/Ownable.sol";

contract Token is ERC20, Ownable {
    /**
     * @dev assign totalSupply to account creating this contract */    
    string  public name = "wAMKN";
    string public symbol = "AMKN"; 
    string  public bitclout_publicKey = "BC1YLfnXhUZD7cHQvoTonWZ4BMyhvV3XbWBvkbci6J8XbXgy8fkYdGH";
    constructor() public 
    {
        _mint(msg.sender, 1900);
        // Always set to 1900
    }
}
