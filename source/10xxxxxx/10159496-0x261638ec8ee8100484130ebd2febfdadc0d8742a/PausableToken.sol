pragma solidity ^0.4.23;

import "./StandardToken.sol";
import "./Pausable.sol";
import "./RBAC.sol";


contract PausableToken is StandardToken, Pausable, RBAC {

    string public constant ROLE_ADMINISTRATOR = "administrator";

    modifier whenNotPausedOrAuthorized() {
        require(!paused || hasRole(msg.sender, ROLE_ADMINISTRATOR));
        _;
    }
    /**
     * @dev Add an address that can administer the token even when paused.
     * @param _administrator Address of the given administrator.
     * @return True if the administrator has been added, false if the address was already an administrator.
     */
    function addAdministrator(address _administrator) onlyOwner public returns (bool) {
        if (isAdministrator(_administrator)) {
            return false;
        } else {
            addRole(_administrator, ROLE_ADMINISTRATOR);
            return true;
        }
    }

    /**
     * @dev Remove an administrator.
     * @param _administrator Address of the administrator to be removed.
     * @return True if the administrator has been removed,
     *  false if the address wasn't an administrator in the first place.
     */
    function removeAdministrator(address _administrator) onlyOwner public returns (bool) {
        if (isAdministrator(_administrator)) {
            removeRole(_administrator, ROLE_ADMINISTRATOR);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Determine if address is an administrator.
     * @param _administrator Address of the administrator to be checked.
     */
    function isAdministrator(address _administrator) public view returns (bool) {
        return hasRole(_administrator, ROLE_ADMINISTRATOR);
    }

    /**
     * @dev Batch transfer tokens to investors
     * @param users Array of users addresses
     * @param amounts Array of token amounts for users
     */
    function transferBatch(address[] users, uint256[] amounts) public whenNotPausedOrAuthorized {
        require(users.length == amounts.length, "users and amounts have different length");
        for (uint256 i = 0; i < users.length; i++) {
            require(transfer(users[i], amounts[i]), "batch token transfer failed");
        }
    }

    /**
    * @dev Transfer token for a specified address with pause feature for administrator.
    * @dev Only applies when the transfer is allowed by the owner.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public whenNotPausedOrAuthorized returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
    * @dev Transfer tokens from one address to another with pause feature for administrator.
    * @dev Only applies when the transfer is allowed by the owner.
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPausedOrAuthorized returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

