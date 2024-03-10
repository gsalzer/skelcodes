pragma solidity ^0.4.17;

contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
     * Constructor assigns ownership to the ETH address used to deploy the 
     * contract.
     */
    function Ownable() internal {
       owner = msg.sender;
    }

    /**
     * Modifier makes a prerequisite check that restricted functions can be 
     * called given that it is the owner who is executing the functions.
     */
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    /**
     * Allows the owner of the contract to transfer ownership to another ETH
     * address. This function is restricted and can only be called by the 
     * current owner.
     *
     * @param _addr The address which the ownership will be transferred to. 
     */
    function transferOwnership(address _addr) public onlyOwner {
        require(_addr != 0x0);
        owner = _addr;
        OwnershipTransferred(msg.sender, _addr);
    }
}
