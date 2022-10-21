// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Multimanager {
    
    ////////////////////////////////////////
    // MANAGER VARIABLES //
    mapping(address => bool) public managers; 
    address[] public managersArray; 
    address public deployer;
    string[] public messagesArray;
    
    ////////////////////////////////////////                               
    // CONSTRUCTOR //  
    constructor() {
        managers[msg.sender] = true;
        managersArray.push(msg.sender);
        deployer = msg.sender;
    }
    
    function addManagers(address newManagerAddress) public virtual onlyManager{ // Funzione per aggiungere owners
        require(!managers[newManagerAddress]); 
        
        managers[newManagerAddress] = true;
        managersArray.push(newManagerAddress);
    }
    
    function deleteManager(address managerAddress) public virtual onlyManager{ // rimuovere un manager da un array
        if(managerAddress == deployer)
        {
            revert();
        }
        
        require(managers[managerAddress], "Not deleted! Manager not present");
        require(managersArray.length>1, "The contract requires at least one manager"); 
        
        
        delete managers[managerAddress]; // lo elimina dalla maps
        
        //remove from array
        for(uint i = 0; i < managersArray.length; i++)
        {
            if(managersArray[i] == managerAddress)
            {
                delete managersArray[i];
                //managersArray.length--;
                return;
            }
        }
    }
    
    function viewManagers() public view virtual returns(address[] memory){
        return managersArray;
    }
    
    modifier onlyManager() { // permette operazione solo ai managers
        require(managers[msg.sender], "this is not manager");
        _;
    }
    
}
