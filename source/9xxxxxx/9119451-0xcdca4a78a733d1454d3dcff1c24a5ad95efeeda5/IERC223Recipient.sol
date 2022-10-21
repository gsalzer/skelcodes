pragma solidity >=0.4.22 < 0.6.0;

/**
 * @dev Interface of the ERC223 standard as defined in the EIP.
 * Contract that will work with ERC223 tokens.
 */
interface IERC223Recipient {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param spender Token sender address.
     * @param amount Amount of tokens.
     * @param data Transaction metadata.
     *
     * This function may revert to prevent the operation from being executed.
    */
    function tokenFallback(address spender, uint amount, bytes calldata data) external;
}
