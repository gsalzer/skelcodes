pragma solidity ^0.4.20;

contract Owned{
    address public owned;
    
    constructor () public {
        owned = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owned);
        _;
    }
    
    function transferOwnerShip(address newOwer) public onlyOwner {
        owned = newOwer;
    }
}
