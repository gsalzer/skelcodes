pragma solidity ^0.6.4;

contract owned
{
     /*
        1) Allows the manager to pause the main Factory contract
        2) [Very Important]) The new contract that is created by the Factory is NOT owned, and therefore can not in any way be modified by the manager
        3) Only the Factory contract is owned.
    */

    address public manager;
    
    constructor() public 
	{
	    manager = msg.sender;
	}

    modifier onlyManager()
    {
        require(msg.sender == manager);
        _;
    }
    
    function setManager(address newmanager) external onlyManager
    {
        /*
            Allows the current manager to set a new manager
        */
        
        require(newmanager.balance > 0);
        manager = newmanager;
    }
    
}





