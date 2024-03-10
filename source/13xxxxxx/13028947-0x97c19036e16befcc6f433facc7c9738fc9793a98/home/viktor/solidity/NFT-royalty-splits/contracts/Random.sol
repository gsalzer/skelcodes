// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Random is Ownable {
  uint256 private key;
  uint256 private nonce;

  constructor(uint256 _key) {
    key = _key;
  }

  function addNonce() private {
    nonce = ++nonce;
  }

  function getCoinbase() private view returns(address) {
    return block.coinbase;
  }

  function getDifficulty() private view returns(uint256) {
    return block.difficulty;
  }

  function getGaslimit() private view returns(uint256) {
    return block.gaslimit;
  }

  function getNumber() private view returns(uint256) {
   return block.number;
  }

  function getBlockhash1() private view returns(bytes32) {
    return blockhash(block.number - 1);
  }

  function getBlockhash2() private view returns(bytes32) {
    return blockhash(block.number - 2);
  }

  function getBlockhash3() private view returns(bytes32) {
    return blockhash(block.number - 3);
  }

  function getBlockhash4() private view returns(bytes32) {
    return blockhash(block.number - 4);
  }

  function getBlockhash5() private view returns(bytes32) {
    return blockhash(block.number - 5);
  }

  function getTimestamp() private view returns(uint256) {
    return block.timestamp;
  }

  function getData() private pure returns(bytes calldata) {
    return msg.data;
  }

  function getSender() private view returns(address) {
    return msg.sender;
  }

  function getSig() private pure returns(bytes4) {
    return msg.sig;
  }

  function getOrigin() private view returns(address) {
    return tx.origin;
  }

  function encodeMessageData() private view returns(bytes memory) {
    return abi.encodePacked(getData(), getSender(), getSig());
  }

  function A8cf9be874ceefa20f0edbc6d3672c92e058b5703579bf8cc0092763eb913f2eb94b08e0df425f02a0e182335b32c9142f9ad26c6badafcf23f7284f6d600bdde9a08faff17f7f303c1c1063ef141c7aa18c9f8c4d1089397a1005c013c4e165cb55f502c2478b56603768eff9ce17afec7ae4b4e9ef5e7214f11a05382170524d1450d12b38ca252065572b70bd4de9e06afb7ba8d4a45715adde4608ec402358b81b3c2fd2d6cac3acaadbda58b4beb0da4fe77c481197151976dafb2f37ae1652e3ad2ae13583c2839720016c3ca9e9effe305d4fbb743a9b188ab6c7ad2a08096ecfa2b9e4c8d2364998baf954b8ab311ff92c894c5bec269a7fcca1fdbc022ad34b59377cd3d8f127e87d9daca4cff6cb038144b6237c166e5f51cb7417ff698281bf223fef00105550ea55245051d5e6189b242a4cff9d87a34d0c5be4363bf9ae3bb0211ca09902ef09b54dd80098e08a90b7e80d7757efa306c3e1b1fccb519908372b345e3114f66f122c2b85b321bd3bb9a0784db519ab77591bfaadebae05528f8de2c918a33bbb59f7a8832ec77cdf95e097e76cf6597ab2ba7fe845c22d06b29f316e17a89d5f932bfd84f3896dd0b448c2ba4ba83faee5a7e03183d392c7df1df15656dccc86fc50b02026e6a6bcfa848701a634f9aaf08d6e() private {
    addNonce();

    key = uint256(keccak256(abi.encodePacked(
          key,
          getCoinbase(),
          getDifficulty(),
          getGaslimit(),
          getNumber(),
          getBlockhash1(),
          getBlockhash2(),
          getBlockhash3(),
          getBlockhash4(),
          getBlockhash5(),
          getTimestamp(),
          encodeMessageData(),
          getOrigin(),
          nonce)));
  }

  function rand(uint256 _range) onlyOwner public returns(uint256) {
    regenerateHash();
    return key % _range;
  }

  function regenerateHash() onlyOwner public {
    A8cf9be874ceefa20f0edbc6d3672c92e058b5703579bf8cc0092763eb913f2eb94b08e0df425f02a0e182335b32c9142f9ad26c6badafcf23f7284f6d600bdde9a08faff17f7f303c1c1063ef141c7aa18c9f8c4d1089397a1005c013c4e165cb55f502c2478b56603768eff9ce17afec7ae4b4e9ef5e7214f11a05382170524d1450d12b38ca252065572b70bd4de9e06afb7ba8d4a45715adde4608ec402358b81b3c2fd2d6cac3acaadbda58b4beb0da4fe77c481197151976dafb2f37ae1652e3ad2ae13583c2839720016c3ca9e9effe305d4fbb743a9b188ab6c7ad2a08096ecfa2b9e4c8d2364998baf954b8ab311ff92c894c5bec269a7fcca1fdbc022ad34b59377cd3d8f127e87d9daca4cff6cb038144b6237c166e5f51cb7417ff698281bf223fef00105550ea55245051d5e6189b242a4cff9d87a34d0c5be4363bf9ae3bb0211ca09902ef09b54dd80098e08a90b7e80d7757efa306c3e1b1fccb519908372b345e3114f66f122c2b85b321bd3bb9a0784db519ab77591bfaadebae05528f8de2c918a33bbb59f7a8832ec77cdf95e097e76cf6597ab2ba7fe845c22d06b29f316e17a89d5f932bfd84f3896dd0b448c2ba4ba83faee5a7e03183d392c7df1df15656dccc86fc50b02026e6a6bcfa848701a634f9aaf08d6e();
  }
}


