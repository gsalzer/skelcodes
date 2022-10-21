pragma solidity ^0.5.0;

contract Proxy {
    uint256[1000000] private _reserved;
    address public owner = msg.sender;
    address public impl;

    function setImpl(address newImpl) external {
        require(msg.sender == owner, "Proxy: Access denied");
        impl = newImpl;
    }

    function () payable external {
        _delegate(impl);
    }
    
    function _delegate(address implementation)  internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)
            
            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)
            
            // Copy the returned data.
            returndatacopy(0, 0, returndatasize)
            
            switch result
                // delegatecall returns 0 on error.
                case 0 { revert(0, returndatasize) }
                default { return(0, returndatasize) }
        }
    }
}
