pragma solidity ^0.5.4;

contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @dev Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}


contract MKReceiver {

    event Received(uint indexed value, address indexed sender, bytes data);

    address public ownedAddr;

    constructor (address _addr) public{
        ownedAddr = _addr;
    }
    
    function() external payable {
        if(msg.value > 0) {
            emit Received(msg.value, msg.sender, msg.data);
        }
    }
    
    function execute(address destination, uint value, bytes memory data) public {
        
        address addr = Owned(ownedAddr).owner();
        require(addr == msg.sender); 
        
        destination.call.value(value)(data);
    }

}
