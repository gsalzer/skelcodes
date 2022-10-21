pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Mintable.sol";


contract UniMock is ERC20Mintable {
    constructor() public {
        ERC20Mintable.initialize(msg.sender);
    }
}

