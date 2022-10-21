pragma solidity >=0.4.22 <0.6.0;

import './9COS_Token.sol';

contract makeToken is NINESWAPCOIN {
    // initialSupply, tokenName, tokenSymbol
    string public constant name = "NineSwapCoin";
    string public constant symbol = "9COS";
    uint256 public constant _totalSupply = 10000000000;
    uint public constant decimals = 18;
    uint public constant totalSupply = _totalSupply * 10**uint(decimals);
    
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    )
    NINESWAPCOIN(initialSupply, tokenName, tokenSymbol) public {
        initialSupply = 0;
        tokenName = name;
        tokenSymbol = symbol;
        mintToken(msg.sender, totalSupply);
    }
}

