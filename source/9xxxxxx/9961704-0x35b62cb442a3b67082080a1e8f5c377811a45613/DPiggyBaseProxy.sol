pragma solidity ^0.6.4;

import "Address.sol";
import "DPiggyBaseProxyData.sol";
import "DPiggyBaseProxyInterface.sol";

/**
 * @title DPiggyBaseProxy
 * @dev A proxy contract that implements delegation of calls to other contracts.
 * The stored data is on DPiggyBaseProxyData contract.
 */
contract DPiggyBaseProxy is DPiggyBaseProxyData, DPiggyBaseProxyInterface {

    constructor(address _admin, address _implementation, bytes memory data) public payable {
        admin = _admin;
        _setImplementation(_implementation, data);
    } 
  
    /**
     * @dev Fallback function that delegates the execution to an implementation contract.
     */
    fallback() external payable {
        address addr = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
  
    /**
     * @dev Function to be compliance with EIP 897.
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-897.md
     * It is an "upgradable proxy".
     */
    function proxyType() public pure returns(uint256) {
        return 2; 
    }
    
    /**
     * @dev Function to set the proxy implementation address.
     * Only can be called by the proxy admin.
     * The implementation address must a contract.
     * @param newImplementation Address of the new proxy implementation.
     * @param data ABI encoded with signature data that will be delegated over the new implementation.
     */
    function setImplementation(address newImplementation, bytes calldata data) onlyAdmin external override(DPiggyBaseProxyInterface) payable {
        require(Address.isContract(newImplementation));
        address oldImplementation = implementation;
        _setImplementation(newImplementation, data);
        emit SetProxyImplementation(newImplementation, oldImplementation);
    }
    
    /**
     * @dev Function to set the proxy admin address.
     * Only can be called by the proxy admin.
     * @param newAdmin Address of the new proxy admin.
     */
    function setAdmin(address newAdmin) onlyAdmin external override(DPiggyBaseProxyInterface) {
        require(newAdmin != address(0));
        address oldAdmin = admin;
        admin = newAdmin;
        emit SetProxyAdmin(newAdmin, oldAdmin);
    }
    
    /**
     * @dev Internal function to set the implementation address.
     * @param _implementation Address of the new proxy implementation.
     * @param data ABI encoded with signature data that will be delegated over the new implementation.
     */
    function _setImplementation(address _implementation, bytes memory data) internal {
        implementation = _implementation;
        if (data.length > 0) {
            (bool success,) = _implementation.delegatecall(data);
            assert(success);
        }
    }
}

