// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library EditionRoyalty {
  struct Royalty {
    address payable account;
    uint256 value;
  }

  struct Info {
    uint256 id;
    uint256 totalSupply;
    Royalty royalty;
  }
}
