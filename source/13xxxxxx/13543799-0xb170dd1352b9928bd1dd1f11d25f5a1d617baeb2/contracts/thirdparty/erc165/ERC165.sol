// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./IERC165.sol";

// Implementation of the {IERC165} interface.
// Contracts may inherit from this and call {_registerInterface} to declare
// their support of an interface.  Derived contracts must call
// _registerInterface(_INTERFACE_ID_ERC165).
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 internal constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

