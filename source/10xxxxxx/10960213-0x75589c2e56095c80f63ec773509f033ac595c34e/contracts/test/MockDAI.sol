pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockDAI is ERC20 {
    constructor() ERC20("MockDAI", "DAI" ) public {}

    function faucet() public {
      _mint(msg.sender, 10**18);
    }
}

