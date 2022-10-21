pragma solidity 0.5.4;

import "./Ownable.sol";

contract Announcer is Ownable {
    
    event Anchoring(uint256 startBlock, uint256 endBlock, string hashValue); // Event

    constructor()
    Ownable()
    public {

    }

    //Public functions (place the view and pure functions last)
    function announceAnchoring(uint256 startBlock, uint256 endBlock, string memory hashValue) public onlyOwner {
        require(startBlock <= endBlock, 'startBlock <= endBlock');
        require(bytes(hashValue).length > 0, "hashValue cannot be empty");
        emit Anchoring(startBlock, endBlock, hashValue);
    }
}
