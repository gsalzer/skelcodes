// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

/// @title Factory interface with benefits related methods exposed.
/// @notice Interface for claiming, adding and depositing benefits.
interface IWhiteLabelFactory {

  /// @notice Address of the main token.
  /// @return address of the main token.  
  function mainToken() external view returns (address);

  /// @notice Address of the main DAO.
  /// @return address of the main DAO.
  function mainDao() external view returns (address);

  /// @notice Checks whether provided address is a valid DAO.
  /// @param dao_ address to check.
  /// @return bool true if address is a valid DAO.
  function isDao(address dao_) external view returns (bool);

  /// @notice Claim available benefits for holder.
  /// @param amount_ of wei to claim.
  function claimBenefits(uint256 amount_) external;

  /// @notice Adds withdrawal benefits for holder.
  /// @param recipient_ holder that's getting benefits.
  /// @param amount_ benefits amount to be added to holder's existing benefits.
  function addBenefits(address recipient_, uint256 amount_) external;
  
  /// @notice Depositis withdrawal benefits.
  /// @param token_ governing token for DAO that's depositing benefits.
  function depositBenefits(address token_) external payable;
}

