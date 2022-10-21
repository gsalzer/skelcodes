pragma solidity ^0.5.16;

import "./AegisComptrollerCommon.sol";
import "./BaseReporter.sol";

/**
 * @title Aegis Unitroller
 * @author Aegis
 */
contract Unitroller is AegisComptrollerCommon, BaseReporter {
    event NewPendingImplementation(address _oldPendingImplementation, address _newPendingImplementation);
    event NewImplementation(address _oldImplementation, address _newImplementation);
    event NewPendingAdmin(address _oldPendingAdmin, address _newPendingAdmin);
    event NewAdmin(address _oldAdmin, address _newAdmin);

    constructor () public {
        admin = msg.sender;
    }

    function _setPendingImplementation(address _newPendingImplementation) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.ERROR, ErrorRemarks.SET_PENDING_IMPLEMENTATION_OWNER_CHECK, uint(Error.ERROR));
        }
        address oldPendingImplementation = pendingComptrollerImplementation;
        pendingComptrollerImplementation = _newPendingImplementation;
        emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);
        return uint(Error.SUCCESS);
    }

    /**
     * @notice Accepts new implementation of comptroller. msg.sender must be pendingImplementation
     * @return SUCCESS
     */
    function _acceptImplementation() public returns (uint) {
        if (msg.sender != pendingComptrollerImplementation || pendingComptrollerImplementation == address(0)) {
            return fail(Error.ERROR, ErrorRemarks.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK, uint(Error.ERROR));
        }
        address oldImplementation = comptrollerImplementation;
        address oldPendingImplementation = pendingComptrollerImplementation;
        comptrollerImplementation = pendingComptrollerImplementation;
        pendingComptrollerImplementation = address(0);
        emit NewImplementation(oldImplementation, comptrollerImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);
        return uint(Error.SUCCESS);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param _newPendingAdmin address
     * @return SUCCESS
     */
    function _setPendingAdmin(address _newPendingAdmin) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.ERROR, ErrorRemarks.SET_PENDING_ADMIN_OWNER_CHECK, uint(Error.ERROR));
        }
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = _newPendingAdmin;
        emit NewPendingAdmin(oldPendingAdmin, _newPendingAdmin);
        return uint(Error.SUCCESS);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @return SUCCESS
     */
    function _acceptAdmin() public returns (uint) {
        if (msg.sender != pendingAdmin || msg.sender == address(0)) {
            return fail(Error.ERROR, ErrorRemarks.ACCEPT_ADMIN_PENDING_ADMIN_CHECK, uint(Error.ERROR));
        }
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        admin = pendingAdmin;
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
        return uint(Error.SUCCESS);
    }
}
