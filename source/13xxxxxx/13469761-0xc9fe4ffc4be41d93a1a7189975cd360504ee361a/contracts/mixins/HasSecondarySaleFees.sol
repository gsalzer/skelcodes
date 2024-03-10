// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./OZ/ERC165.sol";
import "../interfaces/IHasSecondarySaleFees.sol";

/**
 * @notice An interface for communicating fees to 3rd party marketplaces.
 * @dev Originally implemented in mainnet contract 0x44d6e8933f8271abcf253c72f9ed7e0e4c0323b3
 */
abstract contract HasSecondarySaleFees is Initializable, ERC165, IHasSecondarySaleFees {
  function getFeeRecipients(uint256 id) public view virtual override returns (address payable[] memory);

  function getFeeBps(uint256 id) public view virtual override returns (uint256[] memory);

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    if (interfaceId == type(IHasSecondarySaleFees).interfaceId) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }
}

