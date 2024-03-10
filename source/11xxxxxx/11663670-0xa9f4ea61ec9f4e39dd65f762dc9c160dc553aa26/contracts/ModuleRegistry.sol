//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";

 /// @title   Module Registry Contract
 /// @author  DEXAG, Inc.
 /// @notice  This contract provides the logic for querying, maintaining, and updating Slingshot modules. 
 /// @dev     When a new module is deployed, it must be registered. If the logic for a particular 
 ///          DEX/AMM changes, a new module must be deployed and registered.
contract ModuleRegistry is Ownable {
    /// @notice This is an index which indicates the validity of a module
    mapping(address => bool) public modulesIndex;

    /// @notice Slingshot.sol address
    address public slingshot;

    event ModuleRegistered(address moduleAddress);
    event ModuleUnregistered(address moduleAddress);
    event NewSlingshot(address oldAddress, address newAddress);

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /// @notice Checks if given address is a module
    /// @param _moduleAddress Address of the module in question
    /// @return true if address is module
    function isModule(address _moduleAddress) external view returns (bool) {
        return modulesIndex[_moduleAddress];
    }

    /// @param _moduleAddress Address of the module to register
    function registerSwapModule(address _moduleAddress) external onlyOwner {
        modulesIndex[_moduleAddress] = true;
        emit ModuleRegistered(_moduleAddress);
    }

    /// @param _moduleAddress Address of the module to unregister
    function unregisterSwapModule(address _moduleAddress) external onlyOwner {
        delete modulesIndex[_moduleAddress];
        emit ModuleRegistered(_moduleAddress);
    }

    /// @param _slingshot Slingshot.sol address implementation
    function setSlingshot(address _slingshot) external onlyOwner {
        address oldAddress = slingshot;
        slingshot = _slingshot;
        emit NewSlingshot(oldAddress, _slingshot);
    }
}

