// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

/**
 * @notice A place for common modifiers and functions used by various NFT721 mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFT721Core {
  uint256[1000] private ______gap;
}

