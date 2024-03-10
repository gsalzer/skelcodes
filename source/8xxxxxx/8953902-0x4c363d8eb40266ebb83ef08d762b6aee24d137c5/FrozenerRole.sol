pragma solidity ^0.5.0;

import "./Roles.sol";
import "./Ownable.sol";

contract FrozenerRole is Ownable {
    using Roles for Roles.Role;

    event FrozenerAdded(address indexed account);
    event FrozenerRemoved(address indexed account);

    Roles.Role private _Frozeners;

    modifier whenNotFrozen() {
        require(!isFrozener(msg.sender), "FrozenerRole: caller frozen");
        _;
    }

    function isFrozener(address account) public view returns (bool) {
        return _Frozeners.has(account);
    }

    function addFrozener(address account) public onlyOwner {
        _addFrozener(account);
    }

    function renounceFrozener(address account) public onlyOwner {
        _removeFrozener(account);
    }

    function _addFrozener(address account) internal {
        _Frozeners.add(account);
        emit FrozenerAdded(account);
    }

    function _removeFrozener(address account) internal {
        _Frozeners.remove(account);
        emit FrozenerRemoved(account);
    }
}

