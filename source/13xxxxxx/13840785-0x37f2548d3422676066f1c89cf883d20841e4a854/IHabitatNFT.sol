// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './EditionRoyalty.sol';

interface IHabitatNFT {
  function mint(
    address account,
    uint256 id,
    uint256 amount,
    EditionRoyalty.Royalty memory editionRoyalty,
    bytes memory data
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
  
  function burn(
    address from,
    uint256 id,
    uint256 amount
    ) external;
}

