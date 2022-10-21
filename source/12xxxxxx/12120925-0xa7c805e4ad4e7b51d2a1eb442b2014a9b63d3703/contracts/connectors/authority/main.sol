pragma solidity ^0.7.0;

import { AccountInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract AuthorityResolver is Events, Helpers {
    /**
     * @dev Add New authority
     * @param authority authority Address.
     */
    function add(
        address authority
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        AccountInterface(address(this)).enable(authority);

        _eventName = "LogAddAuth(address,address)";
        _eventParam = abi.encode(msg.sender, authority);
    }

    /**
     * @dev Remove authority
     * @param authority authority Address.
     */
    function remove(
        address authority
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(checkAuthCount() > 1, "Removing-all-authorities");
        AccountInterface(address(this)).disable(authority);

        _eventName = "LogRemoveAuth(address,address)";
        _eventParam = abi.encode(msg.sender, authority);
    }
}

contract ConnectV2Auth is AuthorityResolver {
    string public constant name = "Auth-v1";
}

