// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title SocialProofable
 * @dev Used to define the social proof for a specific token.
 *      Based on the proposal by Dan Levine:
 *      https://docs.google.com/document/d/1wbsqYC6ZqZZdaz3li3UAFaXT2Yrc8G8KUDu7F3KrQ6Y/edit
 *
 * @author @Onchained
 */
interface SocialProofable {
  function getTwitter() external view returns(string memory);
  function getTwitterProof() external view returns(uint256);
  function getTelegram() external view returns(string memory);
  function getWebsite() external view returns(string memory);
  function getGithub() external view returns(string memory);
  function getGithubProof() external view returns(bytes memory);
}

