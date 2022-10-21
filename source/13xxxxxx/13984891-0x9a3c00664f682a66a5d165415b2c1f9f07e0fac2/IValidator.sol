// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Interface for a validation mechanism for mint destination addresses.
 */
interface IValidator {
    
  /**
   * Get error message for this validator.
   */   
  function errorMessage() external view returns (string memory);

  /**
   * Validates that the given destination address is validate for a mint. Function
   * will return false if validation fails.
   */
  function validateMint(address _to) external view returns (bool);
}

