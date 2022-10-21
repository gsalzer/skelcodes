pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Mintable.sol";


contract DoughMock is ERC20Mintable {
    constructor() public {
        ERC20Mintable.initialize(msg.sender);
    }
}

