// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./IERC1820RegistryUpgradeable.sol";

library Constants {
  IERC1820RegistryUpgradeable public constant REGISTRY = IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

  bytes32 public constant TOKENS_SENDER_INTERFACE_HASH =
  0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;

  bytes32 public constant TOKENS_RECIPIENT_INTERFACE_HASH =
  0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  bytes32 public constant ACCEPT_MAGIC =
  0xa2ef4600d742022d532d4747cb3547474667d6f13804902513b2ec01c848f4b4;

  bytes4 public constant ERC165_INTERFACE_ID_ERC165 = 0x01ffc9a7;
  bytes4 public constant ERC165_INTERFACE_ID_ERC721 = 0x80ac58cd;
}
