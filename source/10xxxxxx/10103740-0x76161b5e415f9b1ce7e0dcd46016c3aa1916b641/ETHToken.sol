pragma solidity ^0.4.17;

import "./MintableToken.sol";

contract ETHToken is MintableToken {

    uint8 public decimals;
    string public name;
    string public symbol;

    /**
     * Constructor initializes the decimals to 18, the name to ETH Token and the 
     * symbol to EEE.
     */
    function ETHToken() public {
        totalSupply = 0;
        decimals = 18;
        name = "ETH Token";
        symbol = "EEE";
    } 
}
