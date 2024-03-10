// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract Describable {
    string private _description;

    function _setupDescription(string memory description) internal {
        _description = description;
    }

    function description() public view returns (string memory) {
        return _description;
    }
}

