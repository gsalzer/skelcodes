pragma solidity ^0.5.16;

import "./Ownable.sol";


contract Administrable is Ownable {
    event AdminstratorAdded(address adminAddress);
    event AdminstratorRemoved(address adminAddress);

    mapping (address => bool) public administrators;

    modifier onlyAdministrator() {
        require(administrators[msg.sender] || owner == msg.sender); // owner is an admin by default
        _;
    }

    /// @notice Add an administrator
    /// @param _adminAddress The new administrator address
    function addAdministrators(address _adminAddress) public onlyOwner {
        administrators[_adminAddress] = true;
        emit AdminstratorAdded(_adminAddress);
        return;
    }

    /// @notice Remove an administrator
    /// @param _adminAddress The administrator address to remove
    function removeAdministrators(address _adminAddress) public onlyOwner {
        delete administrators[_adminAddress];
        emit AdminstratorRemoved(_adminAddress);
        return;
    }
}

