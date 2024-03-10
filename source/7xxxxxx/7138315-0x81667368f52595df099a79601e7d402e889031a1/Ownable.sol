pragma solidity ^0.5;

contract Ownable {

    mapping(uint => string) public data;
    
    function addData(string memory inData) public {
        data[1] = inData;
    }

}
