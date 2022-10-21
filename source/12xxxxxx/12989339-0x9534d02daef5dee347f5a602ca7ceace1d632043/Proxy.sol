// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

// This is mostly lifted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol
// Honorably mentions should be: https://fravoll.github.io/solidity-patterns/proxy_delegate.html
// which guided me to: https://github.com/fravoll/solidity-patterns/tree/master/ProxyDelegate

// Good Info here: https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable

// Sample ERC721 Upgradable contract: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/tree/master/contracts/token/ERC721

abstract contract Proxy is Ownable {

    address internal _delegateAddress;
    
    function GetLogic() external view onlyOwner returns (address) {
        return _delegateAddress;
    }

    function SetLogic(address delegate) external onlyOwner {
        _delegateAddress = delegate;
    }

    fallback () external payable {
        _delegate(_delegateAddress);
    }

    receive () external payable {
        _delegate(_delegateAddress);
    }
    
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            //Optional, if we wan't to get rid of the param to this function, load from member variable
            //let _target := sload(0)
            
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

abstract contract ProxyTarget is Ownable {
    address internal _delegateAddress;
    
    function GetLogicContract() external view onlyOwner returns (address) {
        return _delegateAddress;
    }
}
