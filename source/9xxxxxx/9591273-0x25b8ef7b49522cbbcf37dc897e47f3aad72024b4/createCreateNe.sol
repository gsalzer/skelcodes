pragma solidity ^0.5.12;

contract createMe {
    uint public number;

    constructor(uint256 x) public {
        number = x;
    }
}

contract createCreateNe {
    address public lastCreatedAddress;
    uint public x;

    function() external {
        require(x != 0, "WC'S COFFEE IS THE BEST");
    }
    
    function createContract() public {
        createMe S = new createMe(block.number);
        lastCreatedAddress = address(S);
    }
}
