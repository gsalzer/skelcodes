// SPDX-License-Identifier: P-P-P-PONZO!!!
pragma solidity ^0.7.4;

/* ROOTKIT: The Age of Forks
Intended use:
- Raise any token using the MarketGeneration
and MarketDistribution contract
- combine with an ERC-31337 version of the 
raised token.


A Rooted Token is a token that gains in value
against whatever token it is paired with. In
some ways Rootkit.finance is just Rooted ETH. 
Its time to ROOT EVERYTHING ON EVERY CHAIN!!
*/

import "./GatedERC20.sol";


abstract contract RootedToken is GatedERC20("RootKit", "ROOT")
{
    constructor()
    {
        //_mint(msg.sender, 1000000 ether);
    }
}
