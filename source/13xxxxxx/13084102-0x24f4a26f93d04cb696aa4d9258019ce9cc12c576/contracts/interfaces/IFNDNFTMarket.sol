// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable

pragma solidity ^0.7.0;

interface IFNDNFTMarket {
  function getFeeConfig()
    external
    view
    returns (
      uint256 primaryFoundationFeeBasisPoints,
      uint256 secondaryFoundationFeeBasisPoints,
      uint256 secondaryCreatorFeeBasisPoints
    );
}

