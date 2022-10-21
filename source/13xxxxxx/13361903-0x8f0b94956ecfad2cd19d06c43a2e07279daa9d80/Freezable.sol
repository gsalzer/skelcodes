// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Pausable.sol";

contract Freezable is Pausable {
    mapping (address => bool) unfrozenAccounts;

    event Freeze(address indexed account);
    event Unfreeze(address indexed account);

    function _frozen(address account) internal view returns (bool) {
        return !unfrozenAccounts[account];
    }

    function _freeze(address account, bool frozen) internal {
        unfrozenAccounts[account] = !frozen;
    }

    modifier whenUnfrozen(address account) {
        require(!_frozen(account), "account is frozen");
        _;
    }

    function frozen(address account) public view returns (bool) {
        return _frozen(account);
    }

    function freeze(address account) public onlyOwner {
        _freeze(account, true);
        emit Freeze(account);
    }

    function unfreeze(address account) public onlyOwner {
        _freeze(account, false);
        emit Unfreeze(account);
    }

    function _beforeTransfer(address from, address to) internal whenNotPaused whenUnfrozen(from) whenUnfrozen(to) {
    }

    modifier whenTransfer(address from, address to) {
        _beforeTransfer(from, to);
	_;
    }
}

