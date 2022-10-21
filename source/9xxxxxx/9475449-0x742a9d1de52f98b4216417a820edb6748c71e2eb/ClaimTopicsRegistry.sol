// File: contracts/registry/IClaimTopicsRegistry.sol

pragma solidity ^0.5.10;

interface IClaimTopicsRegistry{
    // EVENTS
    event ClaimTopicAdded(uint256 indexed claimTopic);
    event ClaimTopicRemoved(uint256 indexed claimTopic);

    // OPERATIONS
    function addClaimTopic(uint256 claimTopic) external;
    function removeClaimTopic(uint256 claimTopic) external;

    // GETTERS
    function getClaimTopics() external view returns (uint256[] memory);
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/registry/ClaimTopicsRegistry.sol

pragma solidity ^0.5.10;



contract ClaimTopicsRegistry is IClaimTopicsRegistry, Ownable {
    uint256[] claimTopics;

    /**
    * @notice Add a trusted claim topic (For example: KYC=1, AML=2).
    * Only owner can call.
    *
    * @param claimTopic The claim topic index
    */
    function addClaimTopic(uint256 claimTopic) public onlyOwner {
        uint length = claimTopics.length;
        for(uint i = 0; i<length; i++){
            require(claimTopics[i]!=claimTopic, "claimTopic already exists");
        }
        claimTopics.push(claimTopic);
        emit ClaimTopicAdded(claimTopic);
    }

    /**
    * @notice Remove a trusted claim topic (For example: KYC=1, AML=2).
    * Only owner can call.
    *
    * @param claimTopic The claim topic index
    */
    function removeClaimTopic(uint256 claimTopic) public onlyOwner {
        uint length = claimTopics.length;
        for (uint i = 0; i<length; i++) {
            if(claimTopics[i] == claimTopic) {
                delete claimTopics[i];
                claimTopics[i] = claimTopics[length-1];
                delete claimTopics[length-1];
                claimTopics.length--;
                emit ClaimTopicRemoved(claimTopic);
                return;
            }
        }
    }

    /**
    * @notice Get the trusted claim topics for the security token
    *
    * @return Array of trusted claim topics
    */
    function getClaimTopics() public view returns (uint256[] memory) {
        return claimTopics;
    }
}
