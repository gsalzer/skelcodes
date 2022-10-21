pragma solidity 0.5.12;

import "./StateManager.sol";

/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 */
contract ERC20Pausable is StateManager {
    function transfer(address to, uint256 value)
        public
        whenNotPaused
        notBlacklisted
        notBlocked
        returns (bool)
    {
        require(!isBlacklisted(to), "Cannot send to Blacklisted Address");
        require(!isBlocked(to), "Cannot send to blocked Address");
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value)
        public
        whenNotPaused
        notBlacklisted
        notBlocked
        returns (bool)
    {
        require(!isBlacklisted(to), "Cannot send to Blacklisted Address");
        require(!isBlocked(to), "Cannot send to blocked Address");
        require(!isBlacklisted(from), "Cannot send from Blacklisted Address");
        require(!isBlocked(from), "Cannot send from blocked Address");
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value)
        public
        whenNotPaused
        notBlacklisted
        notBlocked
        returns (bool)
    {
        require(!isBlacklisted(spender), "Cannot send to Blacklisted Address");
        require(!isBlocked(spender), "Cannot send to blocked Address");
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenNotPaused
        notBlacklisted
        notBlocked
        returns (bool)
    {
        require(!isBlacklisted(spender), "Cannot send to Blacklisted Address");
        require(!isBlocked(spender), "Cannot send to blocked Address");
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        whenNotPaused
        notBlacklisted
        notBlocked
        returns (bool)
    {
        require(!isBlacklisted(spender), "Cannot send to Blacklisted Address");
        require(!isBlocked(spender), "Cannot send to blocked Address");
        return super.decreaseAllowance(spender, subtractedValue);
    }

    uint256[50] private erc20PausableGap;
}

