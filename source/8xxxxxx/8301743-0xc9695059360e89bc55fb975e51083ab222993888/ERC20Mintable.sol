pragma solidity ^0.4.25;

import "./ERC20.sol";
import "./MinterRole.sol";

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _value) public onlyMinter returns (bool) {
    _mint(_to, _value);
    return true;
  }

/**
   * @dev Function to burn tokens
   * @param _value The amount of tokens to burn from sender's account.
   * @return A boolean that indicates if the operation was successful.
   */
  function burn(uint256 _value) public onlyMinter returns (bool) {
    _burn(msg.sender, _value);
    return true;
  }
}

