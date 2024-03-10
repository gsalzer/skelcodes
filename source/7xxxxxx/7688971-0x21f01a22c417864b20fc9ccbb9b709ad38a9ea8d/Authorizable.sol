pragma solidity ^0.5.7;

import {Ownable} from "./Ownable.sol";

/// Access control utility to provide onlyAuthorized and onlyUserApproved modifiers
contract Authorizable is Ownable {

    // Logs when a currently authorized address is authorized or deauthorized.
    event AuthorizedAddressChanged(
        address indexed target,
        address indexed caller,
        bool allowed
    );

    // Logs when an address is user approved or unapproved.
    event UserApprovedAddressChanged(
        address indexed target,
        address indexed caller,
        bool allowed
    );

    /// Only authorized senders can invoke functions with this modifier.
    modifier onlyAuthorized() {
        require(
            authorized[msg.sender],
            "SENDER_NOT_AUTHORIZED"
        );
        _;
    }

    /// Only user approved senders can invoke functions with this modifier.
    modifier onlyUserApproved(address user) {
        require(
            userApproved[user][msg.sender],
            "SENDER_NOT_APPROVED"
        );
        _;
    }

    // Mapping of authorized addresses.
    // authorized[target] = isAuthorized
    mapping(address => bool) public authorized;

    // Mapping of user approved addresses.
    // userApproved[user][target] = isUserApproved
    mapping(address => mapping(address => bool)) public userApproved;

    address[] authorities;
    mapping(address => address[]) userApprovals;

    /// Modifies authorization of an address. Only contract owner can call this function.
    /// @param target Address to authorize / deauthorize.
    /// @param allowed Whether the target address is authorized.
    function authorize(address target, bool allowed)
    external
    onlyOwner
    {
        if (authorized[target] == allowed) {
            return;
        }
        if (allowed) {
            authorized[target] = allowed;
            authorities.push(target);
        } else {
            delete authorized[target];
            for (uint256 i = 0; i < authorities.length; i++) {
                if (authorities[i] == target) {
                    authorities[i] = authorities[authorities.length - 1];
                    authorities.length -= 1;
                    break;
                }
            }
        }
        emit AuthorizedAddressChanged(target, msg.sender, allowed);
    }

    /// Modifies user approvals of an address.
    /// @param target Address to approve / unapprove.
    /// @param allowed Whether the target address is user approved.
    function userApprove(address target, bool allowed)
    public
    {
        if (userApproved[msg.sender][target] == allowed) {
            return;
        }
        if (allowed) {
            userApproved[msg.sender][target] = allowed;
            userApprovals[msg.sender].push(target);
        } else {
            delete userApproved[msg.sender][target];
            for (uint256 i = 0; i < userApprovals[msg.sender].length; i++) {
                if (userApprovals[msg.sender][i] == target) {
                    userApprovals[msg.sender][i] = userApprovals[msg.sender][userApprovals[msg.sender].length - 1];
                    userApprovals[msg.sender].length -= 1;
                    break;
                }
            }
        }
        emit UserApprovedAddressChanged(target, msg.sender, allowed);
    }

    /// Batch modifies user approvals.
    /// @param targetList Array of addresses to approve / unapprove.
    /// @param allowedList Array of booleans indicating whether the target address is user approved.
    function batchUserApprove(address[] calldata targetList, bool[] calldata allowedList)
    external
    {
        for (uint256 i = 0; i < targetList.length; i++) {
            userApprove(targetList[i], allowedList[i]);
        }
    }

    /// Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
    external
    view
    returns (address[] memory)
    {
        return authorities;
    }

    /// Gets all user approved addresses.
    /// @return Array of user approved addresses.
    function getUserApprovedAddresses()
    external
    view
    returns (address[] memory)
    {
        return userApprovals[msg.sender];
    }
}
