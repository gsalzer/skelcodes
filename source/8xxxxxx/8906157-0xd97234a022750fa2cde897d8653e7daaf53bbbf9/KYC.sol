/**
 *Submitted for verification at Etherscan.io on 2019-07-19
*/

pragma solidity ^0.5.7;

// File: contracts/Ownable/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/KYC/IKYC.sol

/// @title IKYC
/// @notice This contract represents interface for KYC contract
contract IKYC {
    // Fired after the status for a manager is updated
    event ManagerStatusUpdated(address KYCManager, bool managerStatus);

    // Fired after the status for a user is updated
    event UserStatusUpdated(address user, bool status);

    /// @notice Sets status for a manager
    /// @param KYCManager The address of manager for which the status is to be updated
    /// @param managerStatus The status for the manager
    /// @return status of the transaction
    function setKYCManagerStatus(address KYCManager, bool managerStatus)
        public
        returns (bool);

    /// @notice Sets status for a user
    /// @param userAddress The address of user for which the status is to be updated
    /// @param passedKYC The status for the user
    /// @return status of the transaction
    function setUserAddressStatus(address userAddress, bool passedKYC)
        public
        returns (bool);

    /// @notice returns the status of a user
    /// @param userAddress The address of user for which the status is to be returned
    /// @return status of the user
    function getAddressStatus(address userAddress) public view returns (bool);

}

// File: contracts/KYC/KYC.sol

/// @title A contract for KYC of platform users
/// @notice This contract is used to authorize any address who is interacting with the ChelleCoin smart contracts platform
contract KYC is IKYC, Ownable {
    mapping(address => bool) private userStatuses; // A mapping for users and their status i.e. eligible / non-eligible
    mapping(address => bool) public KYCManagers; // A mapping for managers and their status i.e. eligible / non-eligible

    /**
     * @dev Throws if called by any account other than Managers.
     */
    modifier onlyKYCManager() {
        require(
            KYCManagers[msg.sender],
            "Only KYC manager can call this function."
        );
        _;
    }

    /// @notice Sets status for a manager
    /// @param KYCManager The address of manager for which the status is to be updated
    /// @param managerStatus The status for the manager
    /// @return status of the transaction
    function setKYCManagerStatus(address KYCManager, bool managerStatus)
        public
        onlyOwner
        returns (bool)
    {
        require(
            KYCManager != address(0),
            "Provided mannager address is not valid."
        );
        require(
            KYCManagers[KYCManager] != managerStatus,
            "This status of manager is already set."
        );

        KYCManagers[KYCManager] = managerStatus;

        emit ManagerStatusUpdated(KYCManager, managerStatus);

        return true;
    }

    /// @notice Sets status for a user
    /// @param userAddress The address of user for which the status is to be updated
    /// @param passedKYC The status for the user
    /// @return status of the transaction
    function setUserAddressStatus(address userAddress, bool passedKYC)
        public
        onlyKYCManager
        returns (bool)
    {
        require(
            userAddress != address(0),
            "Provided user address is not valid."
        );
        require(
            userStatuses[userAddress] != passedKYC,
            "This status of user is already set."
        );

        userStatuses[userAddress] = passedKYC;

        emit UserStatusUpdated(userAddress, passedKYC);

        return true;
    }

    /// @notice returns the status of a user
    /// @param userAddress The address of user for which the status is to be returned
    /// @return status of the user
    function getAddressStatus(address userAddress) public view returns (bool) {
        require(
            userAddress != address(0),
            "Provided user address is not valid."
        );
        return userStatuses[userAddress];
    }
}
