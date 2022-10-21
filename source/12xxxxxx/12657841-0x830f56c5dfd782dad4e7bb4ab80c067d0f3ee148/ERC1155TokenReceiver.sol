// SPDX-License-Identifier: U-U-U-UPPPP
pragma solidity ^0.5.0;

import "./IERC1155TokenReceiver.sol";

contract ERC1155TokenReceiver is IERC1155TokenReceiver
{
  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external returns(bytes4)
  {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external returns(bytes4)
  {
    return this.onERC1155BatchReceived.selector;
  }
}
