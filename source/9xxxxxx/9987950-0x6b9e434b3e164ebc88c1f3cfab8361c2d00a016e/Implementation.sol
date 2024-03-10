pragma solidity ^0.5.17;


contract Implementation {

    bool public isSetup;
    address implementation;

    /**
     * @dev Sets the address of the current implementation
     * @param _newImp address of the new implementation
     */
    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }
}

