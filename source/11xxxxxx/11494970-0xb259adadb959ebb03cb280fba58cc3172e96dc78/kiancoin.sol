pragma solidity ^0.6.12;

import "./ERC20.sol";

contract kiancoin is ERC20 {
    string public _name = "kiancoin";
    string public _symbol = "KIAN";
    uint public _initial_supply = 1_000_000_000_000_000_000;

    constructor() public ERC20(_name, _symbol) {
        _mint(msg.sender, _initial_supply);
    }

    function helloWorld() public pure returns (string memory) {
        return "hellooo";
    }
}

