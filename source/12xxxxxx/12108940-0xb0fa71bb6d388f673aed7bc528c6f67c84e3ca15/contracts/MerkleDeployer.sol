pragma solidity 0.6.11;

import 'OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/access/Ownable.sol';
import './MerkleDistributor.sol';

contract MerkleDeployer is Ownable {
  function deploy(address token, bytes32 merkleRoot)
    external
    onlyOwner
    returns (MerkleDistributor)
  {
    MerkleDistributor distributor = new MerkleDistributor(token, merkleRoot);
    distributor.transferOwnership(msg.sender);
    return distributor;
  }
}

