// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable

pragma solidity ^0.7.0;

interface IFNDNFTMarket {
  function getFeeConfig()
    external
    view
    returns (
      uint256 primaryF8nFeeBasisPoints,
      uint256 secondaryF8nFeeBasisPoints,
      uint256 secondaryCreatorFeeBasisPoints
    );
}

