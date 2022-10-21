pragma solidity ^0.6.4;

/**
 * @title DPiggyBaseProxyData
 * @dev Contract for all DPiggyBaseProxyData stored data.
 */
contract DPiggyBaseProxyData {
    
    /**
     * @dev Emitted when the proxy implementation has been changed.
     * @param newImplementation Address of the new proxy implementation.
     * @param oldImplementation Address of the previous proxy implementation.
     */
    event SetProxyImplementation(address indexed newImplementation, address oldImplementation);
    
    /**
     * @dev Emitted when the admin address has been changed.
     * @param newAdmin Address of the new admin.
     * @param oldAdmin Address of the previous admin.
     */
    event SetProxyAdmin(address indexed newAdmin, address oldAdmin);
    
    /**
     * @dev Modifier to check if the `msg.sender` is the admin.
     * Only admin address can execute.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    /**
     * @dev The contract address of the implementation.
     */
    address public implementation;
    
    /**
     * @dev The admin address.
     */
    address public admin;
}

