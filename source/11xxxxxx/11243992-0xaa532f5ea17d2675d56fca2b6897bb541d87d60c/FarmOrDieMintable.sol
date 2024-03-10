pragma solidity >=0.4.22 <0.8.0;

import "./FarmOrDie.sol";
import "./MinterRole.sol";

/**
 * @title FarmOrDieMintable
 * @dev FarmOrDie minting logic.
 */
contract FarmOrDieMintable is FarmOrDie, MinterRole {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function _mint(address to, uint256 value) public onlyMinter returns (bool) {
        mint(to, value);
        return true;
    }
}

