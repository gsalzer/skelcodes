// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

// t.me/Flokiv2
// This time 100% no tax
// New Dev also working on $STARL

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    address public owner = msg.sender;
    
    constructor () public ERC20("Free Britney t.me/free_britney_now", "FBRIT") {
        _mint(msg.sender, 10000000000000 * (10 ** uint256(decimals())));
    }
    
    function transferOwner(address newOwner) external {
    require(msg.sender == owner, 'only owner');
    owner = newOwner;
  }
}
