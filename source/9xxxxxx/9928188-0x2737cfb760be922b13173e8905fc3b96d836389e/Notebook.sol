pragma solidity ^0.6.6;

contract Notebook {
    bytes32 public constant version = "EtherNote v0.1.1";
    address public immutable owner = msg.sender;
    string public settings;

    event Settings();
    event Note();

    function update_settings(string memory new_settings) public {
        require(msg.sender == owner, "Permission denied.");
        settings = new_settings;
        emit Settings();
    }

    fallback() external {
        require(msg.sender == owner, "Permission denied.");
        emit Note();
    }
}
