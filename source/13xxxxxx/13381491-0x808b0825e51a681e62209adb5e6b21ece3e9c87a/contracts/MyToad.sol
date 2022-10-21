// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToad is ERC1155, Ownable {
  constructor() ERC1155("https://ipfs.io/ipfs/QmTkw7ySiWXr4fY1qwLdAjdRLptc4TMBN4ewxUZLBWizba") { 
    _mint(msg.sender, 1, 2500, "");
  }
}
