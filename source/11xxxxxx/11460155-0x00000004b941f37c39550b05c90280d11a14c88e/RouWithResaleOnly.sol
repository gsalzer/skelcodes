// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibBaseAuth.sol";


contract WithResaleOnly is BaseAuth {
    mapping (address => bool) private _resaleOnly;


    function setResaleOnlys(address[] memory accounts, bool[] memory values)
        external
        onlyAgent
    {
        for (uint8 i = 0; i < accounts.length; i++) {
            _resaleOnly[accounts[i]] = values[i];
        }
    }

    function isResaleOnly(address account)
        public
        view
        returns (bool)
    {
        return _resaleOnly[account];
    }
}

