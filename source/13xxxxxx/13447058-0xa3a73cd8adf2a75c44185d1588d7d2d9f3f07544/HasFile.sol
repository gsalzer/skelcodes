// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Fully On-Chain File Access Interface -- Single file per token variant
 * Interface for contracts which expose a single file for each of their tokens.
 * Originally created for the NonagonCup.
 */
 interface HasFile {

   /**
    * @dev Each file must have a filename including the file extension, for example:  "my-file-1.stl"
    * If the contract is an NFT where the object of the NFT is the exposed files then the filenames
    * within the contract must be unique and must include the tokenId that they belong to.
    */
   function getFilename(uint256 tokenId) external view returns(string memory filename);

   /**
    * @dev Single call to get the full file contents.
    * NB: This may not work in all conditions due to gas limits, it is instead
    * recommended to call getFileChunksTotal and iterate calls to getFileChunk.
    */
   function getFullFile(uint256 tokenId) external view returns(bytes memory fileContents);


   /**
    * @dev Each file has zero or more fileChunks.
    */
   function getFileChunksTotal(uint256 tokenId) external view returns(uint256 count);


   /**
    * @dev Use repeated calls to getFileChunk to get the binary data for the file.
    *  -- Size of returned data for each fileChunk must be no more than 1024 bytes.
    *  -- First fileChunk should be the file header, if the file format has one.
    */
   function getFileChunk(uint256 tokenId, uint256 index) external view returns(bytes memory data);

 }

