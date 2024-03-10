// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;


import "./Context.sol";

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract WithClaimableMigrationOwnership is Context{
    address private _migrationOwner;
    address private _pendingMigrationOwner;

    event MigrationOwnershipTransferred(address indexed previousMigrationOwner, address indexed newMigrationOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial migrationMigrationOwner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _migrationOwner = msgSender;
        emit MigrationOwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current migrationOwner.
     */
    function migrationOwner() public view returns (address) {
        return _migrationOwner;
    }

    /**
     * @dev Throws if called by any account other than the migrationOwner.
     */
    modifier onlyMigrationOwner() {
        require(isMigrationOwner(), "WithClaimableMigrationOwnership: caller is not the migrationOwner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current migrationOwner.
     */
    function isMigrationOwner() public view returns (bool) {
        return _msgSender() == _migrationOwner;
    }

    /**
     * @dev Leaves the contract without migrationOwner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current migrationOwner.
     *
     * NOTE: Renouncing migrationOwnership will leave the contract without an migrationOwner,
     * thereby removing any functionality that is only available to the migrationOwner.
     */
    function renounceMigrationOwnership() public onlyMigrationOwner {
        emit MigrationOwnershipTransferred(_migrationOwner, address(0));
        _migrationOwner = address(0);
    }

    /**
     * @dev Transfers migrationOwnership of the contract to a new account (`newOwner`).
     */
    function _transferMigrationOwnership(address newMigrationOwner) internal {
        require(newMigrationOwner != address(0), "MigrationOwner: new migrationOwner is the zero address");
        emit MigrationOwnershipTransferred(_migrationOwner, newMigrationOwner);
        _migrationOwner = newMigrationOwner;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingMigrationOwner() {
        require(msg.sender == _pendingMigrationOwner, "Caller is not the pending migrationOwner");
        _;
    }
    /**
     * @dev Allows the current migrationOwner to set the pendingOwner address.
     * @param newMigrationOwner The address to transfer migrationOwnership to.
     */
    function transferMigrationOwnership(address newMigrationOwner) public onlyMigrationOwner {
        _pendingMigrationOwner = newMigrationOwner;
    }
    /**
     * @dev Allows the _pendingMigrationOwner address to finalize the transfer.
     */
    function claimMigrationOwnership() external onlyPendingMigrationOwner {
        _transferMigrationOwnership(_pendingMigrationOwner);
        _pendingMigrationOwner = address(0);
    }

    /**
     * @dev Returns the current _pendingMigrationOwner
    */
    function pendingMigrationOwner() public view returns (address) {
       return _pendingMigrationOwner;  
    }
}
