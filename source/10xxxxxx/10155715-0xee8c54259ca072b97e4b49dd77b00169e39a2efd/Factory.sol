pragma solidity ^0.6.8;

import './Receiver.sol';

contract ReceiversFactory {

    address public owner;
    mapping ( uint256 => Receiver ) receiversMap;
    uint256 receiverCount = 0;

    constructor() public {
        owner = msg.sender;
    }
    
    /* Receivers managing */
    function createReceivers(uint8 count) public {
        require(msg.sender == owner);
        
        for (uint8 i = 0; i < count; i++) {
            receiversMap[++receiverCount] = new Receiver();
        }
    }
    
    function changeReceiversOwner(address newOwner) public {
        require(msg.sender == owner);
        
        for (uint i = 1; i <= receiverCount; i++) {
            receiversMap[i].changeOwner(newOwner);
        }
    }
    
    function getReceiverAddress(uint receiverId) public view returns (address) {
        return address(receiversMap[receiverId]);
    }
    
    function getReceiversCount() public view returns (uint) {
        return receiverCount;
    }
    
    
    /* ERC20 overrides */
    function receiverBalance(uint256 idx, address contractAddress) public view returns (uint256) {
        return receiversMap[idx].balanceOf(contractAddress);
    }
    

    function sendFunds( uint256 receiverId, address contractAddress, uint256 amount, address receiver ) public returns (bool) {
        require(msg.sender == owner);
        return receiversMap[receiverId].transfer(contractAddress, amount, receiver);
    }

}
