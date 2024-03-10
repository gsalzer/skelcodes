// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AttributesStorage.sol";

contract AttributesDelegate is DelegateStorage {

    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    event NewImplementation(address oldImplementation, address newImplementation);

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    event SetController(address ctrl, bool oldState, bool newState);

    constructor() public {
        admin = msg.sender;
    }

    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {
        require(msg.sender == admin, "Ownable: caller is not the admin");

        address oldPendingImplementation = pendingAttributesImplementation;

        pendingAttributesImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingAttributesImplementation);

        return uint(0);
    }

    function _acceptImplementation() public returns (uint) {
        require(msg.sender == pendingAttributesImplementation && pendingAttributesImplementation != address(0), "Ownable: caller is not the pendingAttributesImplementation");

        address oldImplementation = attributesImplementation;
        address oldPendingImplementation = pendingAttributesImplementation;

        attributesImplementation = pendingAttributesImplementation;

        pendingAttributesImplementation = address(0);

        emit NewImplementation(oldImplementation, attributesImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingAttributesImplementation);

        return uint(0);
    }

    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        require(msg.sender == admin, "Ownable: caller is not the admin");
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = newPendingAdmin;
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
        return uint(0);
    }

    function _acceptAdmin() public returns (uint) {
        require(msg.sender == pendingAdmin && pendingAdmin != address(0), "Ownable: caller is not the pendingAdmin");
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        admin = pendingAdmin;
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(0);
    }

    function _setController(address ctrl, bool state) public returns (uint) {
        require(msg.sender == admin, "Ownable: caller is not the admin");
        bool oldState = controllers[ctrl];
        controllers[ctrl] = state;

        emit SetController(ctrl, oldState, state);

        return uint(0);
    }

    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    
    function _implementation() internal view returns (address) {
        return attributesImplementation;
    }

    fallback() external payable virtual {
        _delegate(_implementation());
    }
}
