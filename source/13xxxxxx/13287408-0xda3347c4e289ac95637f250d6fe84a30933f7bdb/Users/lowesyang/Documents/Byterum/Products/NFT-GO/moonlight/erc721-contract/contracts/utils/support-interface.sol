pragma solidity ^0.8.4;

import "./ERC165.sol";

/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
contract SupportsInterface is ERC165 {
    /**
     * @dev Mapping of supported intefraces.
     * @notice You must not set element 0xffffffff to true.
     */
    mapping(bytes4 => bool) internal supportedInterfaces;

    /**
     * @dev Contract constructor.
     */
    constructor() public {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
    }

    /**
     * @dev Function to check which interfaces are suported by this contract.
     * @param _interfaceID Id of the interface.
     * @return True if _interfaceID is supported, false otherwise.
     */
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        override
        returns (bool)
    {
        return supportedInterfaces[_interfaceID];
    }
}

