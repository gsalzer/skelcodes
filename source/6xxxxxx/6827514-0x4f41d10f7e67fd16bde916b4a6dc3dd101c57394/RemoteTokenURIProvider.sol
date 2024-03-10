pragma solidity ^0.4.24;

/**
 * An interface that the remote token URI provider contract must implement.
 */
contract RemoteTokenURIProvider {
  function tokenURI(uint256 _tokenId) public view returns (string);
}

