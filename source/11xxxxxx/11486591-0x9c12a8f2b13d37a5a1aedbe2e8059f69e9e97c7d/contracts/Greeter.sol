//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;


contract Greeter {
    string public greeting;

    event GreetingChanged(string from, string to);

    constructor(string memory _greeting) {
        greeting = _greeting;

        emit GreetingChanged("", greeting);
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        emit GreetingChanged(greeting, _greeting);

        greeting = _greeting;
    }
}

