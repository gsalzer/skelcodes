pragma solidity ^0.5.12;

contract HelloWorld {
    string public message;
    
    constructor(string memory message2) public {
        message=message2;
    }

    function update(string memory message2) public {
        message=message2;
    }
}
