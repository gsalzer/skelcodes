pragma solidity ^0.4.21;

contract Greeter
    {

    string public greeting;

    constructor () public
        {
        greeting = 'Hello';
        }

    function setGreeting(string _greeting) public
        {
        greeting = _greeting;
        }

    function greet() view public returns (string)
        {
        return greeting;
        }

    }
