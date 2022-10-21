pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract ERC20FixedSupply is ERC20 {
    constructor() public {
        _mint(msg.sender, 1000);
    }
    
    function demo() public pure returns(string memory s) {
        return s;
    }
}

