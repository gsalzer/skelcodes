// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ierc20.sol";

contract Adminable {
    address private _owner;
    address private _pendingOwnerAddr;
    uint private _pendingOwnerBlockNumber;
    mapping (address => bool) private _admins;

    modifier onlyOwner {
        require(msg.sender == _owner, "Sender not owner");
        _;
    }

    modifier onlyAdmin {
        require(_admins[msg.sender], "Sender not admin");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _admins[_owner] = true;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }

    function setAdmin(address account, bool state) public onlyOwner payable {
        require(account != address(0), "New admin is null address");
        
        _admins[account] = state;
    }

    function transferOwner(address account) public onlyOwner payable {
        require(account != address(0), "New owner is null address");

        _pendingOwnerAddr = account;
        _pendingOwnerBlockNumber = block.number;
    }

    function approveTransferOwner() public onlyOwner payable {
        require(_pendingOwnerAddr != address(0), "New owner is null address");
        require(_pendingOwnerBlockNumber != 0, "Indefinite confirmation");
        require(block.number-_pendingOwnerBlockNumber >= 4320, "You can only confirm the transfer after 4320 blocks");

        _owner = _pendingOwnerAddr;
        _cancelTransferOwner();
    }

    function cancelTransferOwner() public onlyOwner payable {
        _cancelTransferOwner();
    }

    function _cancelTransferOwner() internal virtual {
        _pendingOwnerAddr = address(0);
        _pendingOwnerBlockNumber = 0;
    }
}

