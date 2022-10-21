pragma solidity 0.5.10;

/**
 * @title LibAddress 
 * @dev Address related utility functions
 */
library LibAddress
{
    /**
     * @dev Check whether the given address is zero address
     * @param account The address to check against
     * @return bool True if the given address is zero address
     */
    function isOriginAddress(address account) internal pure returns (bool)
    {
        return (account == address(0));
    }
}

