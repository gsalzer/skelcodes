pragma solidity ^0.6.2;

// Forward any incoming Ether to a destination address via "transfer" or "send"

contract Forwarder {

    function Transfer(address payable destinationAddress) public payable {
    destinationAddress.transfer(msg.value);
    }

    function Send(address payable destinationAddress) public payable {
    destinationAddress.send(msg.value);
    }

}
