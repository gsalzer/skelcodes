pragma solidity ^0.4.24;

import "./OwnerRole.sol";

contract CroupierRole is OwnerRole{
    using Roles for Roles.Role;

    event CroupierAdded(address indexed account);
    event CroupierRemoved(address indexed account);

    Roles.Role private _croupiers;

    constructor () internal {
    }

    modifier onlyCroupier() {
        require(isCroupier(msg.sender));
        _;
    }

    function isCroupier(address account) public view returns (bool) {
        return _croupiers.has(account);
    }

    function addCroupier(address account) public onlyOwner {
        _addCroupier(account);
    }

    function removeCroupier(address account) public onlyOwner {
        _removeCroupier(account);
    }

    function _addCroupier(address account) internal {
        _croupiers.add(account);
        emit CroupierAdded(account);
    }

    function _removeCroupier(address account) internal {
        _croupiers.remove(account);
        emit CroupierRemoved(account);
    }
}
