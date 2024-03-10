pragma solidity ^0.5.0;

/**
 * Owned contract
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
     * Constructor
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Only the owner of contract
     */ 
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    /**
     * @dev transfer the ownership to other
     *      - Only the owner can operate
     */ 
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    /** 
     * @dev Accept the ownership from last owner
     */ 
    function acceptOwnership() public {
        require(msg.sender == newOwner, "Only new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
