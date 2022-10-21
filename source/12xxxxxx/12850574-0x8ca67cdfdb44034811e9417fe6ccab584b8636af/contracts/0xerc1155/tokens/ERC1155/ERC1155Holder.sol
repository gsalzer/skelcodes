// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import '../../interfaces/IERC1155TokenReceiver.sol';
import '../../utils/ERC165.sol';

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC165, IERC1155TokenReceiver {
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override
    returns (bool)
  {
    if (_interfaceID == type(IERC1155TokenReceiver).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

