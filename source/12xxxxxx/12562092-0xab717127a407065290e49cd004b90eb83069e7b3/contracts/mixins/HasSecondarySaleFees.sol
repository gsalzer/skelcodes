// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @notice An interface for communicating fees to 3rd party marketplaces.
 * @dev Originally implemented in mainnet contract 0x44d6e8933f8271abcf253c72f9ed7e0e4c0323b3
 */
abstract contract HasSecondarySaleFees is Initializable, ERC165Upgradeable {
  /*
   * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
   * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
   *
   * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
   */
  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  /**
   * @dev Called once after the initial deployment to register the interface with ERC165.
   */
  function _initializeHasSecondarySaleFees() internal initializer {
    _registerInterface(_INTERFACE_ID_FEES);
  }

  function getFeeRecipients(uint256 id) public view virtual returns (address payable[] memory);

  function getFeeBps(uint256 id) public view virtual returns (uint256[] memory);
}

