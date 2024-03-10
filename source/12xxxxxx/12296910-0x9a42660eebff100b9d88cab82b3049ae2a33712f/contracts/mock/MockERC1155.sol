pragma solidity 0.6.12;

import 'OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/token/ERC1155/ERC1155.sol';

contract MockERC1155 is ERC1155('Mock') {
  function mint(uint id, uint amount) public {
    _mint(msg.sender, id, amount, '');
  }
}

