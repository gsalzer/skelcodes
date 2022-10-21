pragma solidity ^0.5.0;

contract Contracts {
    // data structure that stores a contract
    struct Contract {
        uint contractId;
        string data;
    }

    address public owner;

    // it maps the contract's id with the contract
    mapping (uint => Contract) public contracts;

    // event fired when an contract is registered
    event newContractRegistered(uint id);

    // Modifier: check if the caller of the smart contract is the owner
    modifier checkSenderIsOwner {
    	require(msg.sender == owner, "You are not the owner.");
    	_;
    }

    /**
     * Constructor function
     */
    constructor() public
    {
        owner = msg.sender;
    }

    /**
     * Add a new contract. 
     * This function can only be called by the owner of the smart contract.
     *
     * @param _contractId 		Contract Id
     * @param _data		        Contract Data
     */
    function addContract(uint _contractId, string memory _data) public checkSenderIsOwner
    returns(uint)
    {
        Contract storage newContract = contracts[_contractId];
        require(newContract.contractId == 0, "Contract already created.");

        newContract.contractId = _contractId;
        newContract.data = _data;

        // emitting the event that a new contract has been registered
        emit newContractRegistered(_contractId);

        return _contractId;
    }

    /**
     * Get the contract's information.
     *
     * @param _id 	The ID of the contract stored on the blockchain.
     */
    function getContractById(uint _id) public view checkSenderIsOwner
    returns(
    	uint,
    	string memory
    ) {
    	Contract memory i = contracts[_id];

    	return (
    		i.contractId,
    		i.data
    	);
    }
}
