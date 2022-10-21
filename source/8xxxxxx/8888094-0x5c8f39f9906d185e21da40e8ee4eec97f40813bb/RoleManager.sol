// File: contracts/geneaidols/RoleManager.sol

pragma solidity ^0.5.2;


/**
 * @title 
 * @dev see 
 */
contract RoleManager {

    mapping(address => bool) private admins;
    mapping(address => bool) private controllers;

    modifier onlyAdmins {
        require(admins[msg.sender], 'only admins');
        _;
    }

    modifier onlyControllers {
        require(controllers[msg.sender], 'only controllers');
        _;
    } 

    constructor() public {
        admins[msg.sender] = true;
        controllers[msg.sender] = true;
    }

    function addController(address _newController) external onlyAdmins{
        controllers[_newController] = true;
    } 

    function addAdmin(address _newAdmin) external onlyAdmins{
        admins[_newAdmin] = true;
    } 

    function removeController(address _controller) external onlyAdmins{
        controllers[_controller] = false;
    } 
    
    function removeAdmin(address _admin) external onlyAdmins{
        require(_admin != msg.sender, 'unexecutable operation'); //to avoid removing all of them
        admins[_admin] = false;
    } 

    function isAdmin(address addr) external view returns (bool) {
        return (admins[addr]);
    }

    function isController(address addr) external view returns (bool) {
        return (controllers[addr]);
    }

}
