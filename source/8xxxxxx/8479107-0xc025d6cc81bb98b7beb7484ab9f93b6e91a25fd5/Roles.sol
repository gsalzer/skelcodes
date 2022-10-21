pragma solidity 0.4.24;
import "./Modifiers.sol";

contract Roles is Modifiers {
    
    function addAdmin(address _new) external onlyOwner() {
        isAdmin[_new] = true;
    }
    
    function removeAdmin(address _admin) external onlyOwner() {
        isAdmin[_admin] = false;
    }

    function renounceAdmin() external onlyAdmin() {
        isAdmin[msg.sender] = false;
    }

}
