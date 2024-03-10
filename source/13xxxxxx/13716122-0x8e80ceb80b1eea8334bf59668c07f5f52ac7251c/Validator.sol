// File: Validator.sol

pragma solidity ^0.5.0;

/**
 * Interface for a validation mechanism for mint destination addresses.
 */
interface Validator {
    
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

