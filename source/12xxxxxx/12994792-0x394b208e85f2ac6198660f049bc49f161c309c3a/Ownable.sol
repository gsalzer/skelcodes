pragma solidity ^0.8.0;

contract Ownable
{
    address internal owner;
    address internal proposedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
       * @dev modifier to limit access to the owner only
       */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function proposeOwner(address _proposedOwner) public onlyOwner
    {
        require(msg.sender != _proposedOwner, "Ownable: Caller is already owner");
        proposedOwner = _proposedOwner;
    }

    function claimOwnership() public
    {
        require(msg.sender == proposedOwner, "Ownable: Not proposed owner");

        emit OwnershipTransferred(owner, proposedOwner);

        owner = proposedOwner;
        proposedOwner = address(0);
    }
}

