pragma solidity ^0.5.0;

import './Context.sol';
import './Ownable.sol';
import './Roles.sol';
import './RBAC.sol';

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Context, Ownable, RBAC {
    string private constant ROLE_WHITELISTED = "whitelist";

    /**
     * @dev Throws if operator is not whitelisted.
     */
    modifier onlyIfWhitelisted() {
        require(isWhitelist(_msgSender()), "Whitelist: The operator is not whitelisted");
        _;
    }

    /**
     * @dev check current operator is in whitelist
     * @return bool
     */
    function checkWhitelist()
        internal
        view
        returns (bool)
    {
        return isWhitelist(_msgSender());
    }

    /**
     * @dev add an address to the whitelist
     * @param _operator address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address _operator)
        public
        onlyOwner
    {
        addRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev add addresses to the whitelist
     * @param _operators addresses
     * @return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] memory _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }
    /**
     * @dev remove an address from the whitelist
     * @param _operator address
     * @return true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address _operator)
        public
        onlyOwner
    {
        removeRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev remove addresses from the whitelist
     * @param _operators addresses
     * @return true if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] memory _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }

    /**
     * @dev determine if address is in whitelist
     * @param _operator address
     * @return bool
     */
    function isWhitelist(address _operator)
        public
        view
        returns (bool)
    {
        return hasRole(_operator, ROLE_WHITELISTED) || isOwner();
    }
}

