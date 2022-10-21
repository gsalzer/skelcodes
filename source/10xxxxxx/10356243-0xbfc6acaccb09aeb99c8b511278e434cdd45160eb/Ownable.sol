pragma solidity ^0.4.25;

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 * Provides onlyOwnerOrApi modifier, which prevents function from running if it is called by other than above OR from one API code.
 * Provides onlyOwnerOrApiOrContract modifier, which prevents function from running if it is called by other than above OR one smart contract code.
 */
contract Ownable {
    address public superOwnerAddr;
    address public ownerAddr;
    mapping(address => bool) public ApiAddr; // list of allowed api's
    mapping(address => bool) public ContractAddr; // list of allowed contracts

    constructor() public {
        superOwnerAddr = 0x74503e1f191292F70622Fb1293E1cEBf771Beacb;
        ownerAddr = msg.sender;
        ApiAddr[0xCa5aBb22955f99c4D851Cae0FF0c2d8988b4AFcf] = true;
    }

    modifier onlySuperOwner() {
        require(msg.sender == superOwnerAddr, "Access denied for this address. It has to be a superOwner.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddr, "Access denied for this address. It has to be an owner.");
        _;
    }

    modifier onlyOwnerOrApi() {
        require(msg.sender == ownerAddr || ApiAddr[msg.sender] == true, "Access denied for this address. It has to be an owner or api.");
        _;
    }

    modifier onlyOwnerOrApiOrContract() {
        require(msg.sender == ownerAddr || ApiAddr[msg.sender] == true || ContractAddr[msg.sender] == true, "Access denied for this address. It has to be an owner or api or allowed contract.");
        _;
    }

}

