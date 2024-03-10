pragma solidity ^0.6.6;

contract PublicNotebook {
    bytes32 public constant version = "EtherNote v0.1.1";
    string public constant settings = "{\"title\":\"EtherNote 公共笔记本\"}";

    event Note();

    function owner() public view returns (address) {
        return msg.sender;
    }

    function update_settings(string memory new_settings) public {
        require(false, "Permission denied.");
    }

    fallback() external {
        emit Note();
    }
}
