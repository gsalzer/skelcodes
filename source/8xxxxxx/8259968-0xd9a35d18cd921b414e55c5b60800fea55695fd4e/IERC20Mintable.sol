pragma solidity ^0.5.7;

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract IERC20Mintable{
    /**
     * @dev Function to mint coins
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value)
    public
    returns (bool);
}

