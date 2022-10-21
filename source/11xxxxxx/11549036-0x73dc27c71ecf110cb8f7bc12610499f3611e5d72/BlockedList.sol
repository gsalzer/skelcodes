pragma solidity ^0.7.0;
pragma experimental SMTChecker;

//SPDX-License-Identifier: MIT
import "OwnableIf.sol";
import "MTokenControllerIf.sol";
/// @title BlockedList - Maintian the BlockedList, only the owner can add or remove BlockedList addresses.
abstract contract BlockedList is OwnableIf, ERC20ControllerViewIf {
    mapping(address => bool) public blockedList;

    event Blocked(
        address indexed _who,
        bool indexed status
    );

    function _block(address _who, bool _blocked) public onlyOwner {
        require(_who != (address)(0x0), "0 address");
        blockedList[_who] = _blocked;
        emit Blocked(_who, _blocked);
    }

    function blocked(address _who) override view public returns (bool){
        return blockedList[_who];
    }
}

