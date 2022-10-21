// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

contract ERC1155Mintable is ERC1155Upgradeable {

  constructor (
    string memory uri
  ) public {
    __ERC1155_init(uri);
  }

  function mint(address to, uint256 id, uint256 amount, bytes calldata data) external returns (address) {
    _mint(to, id, amount, data);
  }

}

