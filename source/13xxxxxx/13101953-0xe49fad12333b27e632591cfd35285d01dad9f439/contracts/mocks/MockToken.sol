pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "../ERC677.sol";

contract MockToken is ERC677 {
    constructor() ERC777("MockToken", "MTOK", new address[](0)) {
        _mint(msg.sender, 500000000e18, "", "");
    }
}

