pragma solidity ^0.5.16;

interface GIMTokenInterface {
  function transfer(address, uint256) external returns (bool);
  function transferGIM(address, address, uint256) external returns (bool);
}

