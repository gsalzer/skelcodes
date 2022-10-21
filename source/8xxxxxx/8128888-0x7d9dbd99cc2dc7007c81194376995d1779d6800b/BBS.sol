pragma solidity ^0.4.24;

contract BBS {
    event Posted(address indexed author, string content);

    function Post(string memory content) public {
        emit Posted(msg.sender, content);
    }
}
