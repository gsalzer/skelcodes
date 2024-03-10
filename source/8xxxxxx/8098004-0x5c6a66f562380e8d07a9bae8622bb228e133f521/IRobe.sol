pragma solidity ^0.5.0;

import "./IERC721.sol";

/**
  * @title Robe
  * @dev An open standard based on Ethereum ERC 721 to build unique NFT with XML information
  * 
  * @dev This is the main Inteface that identifies a Robe NFT
  * 
  * @author Marco Vasapollo <ceo@metaring.com>
  * @author Alessandro Mario Lagana Toschi <alet@risepic.com>
*/
contract IRobe is IERC721 {

    /**
      * Creates a new ERC 721 NFT
      * @return a unique tokenId
      */
    function mint(bytes calldata payload) external returns(uint256);

    /**
      * Attaches a new ERC 721 NFT to an already-existing Token
      * to create a composed NFT
      * @return a unique tokenId
      */
    function mint(uint256 previousTokenId, bytes calldata payload) external returns(uint256);

    /**
      * @return all the tokenIds that composes the givend NFT
      */
    function getChain(uint256 tokenId) external view returns(uint256[] memory);

    /**
      * @return the root NFT of this tokenId
      */
    function getRoot(uint256 tokenId) external view returns(uint256);

    /**
     * @return the content of a NFT
     */
    function getContent(uint256 tokenId) external view returns(bytes memory);

    /**
     * @return the position in the chain of this NFT
     */
    function getPositionOf(uint256 tokenId) external view returns(uint256);

    /**
     * @return the tokenId of the passed NFT at the given position
     */
    function getTokenIdAt(uint256 tokenId, uint256 position) external view returns(uint256);

    /**
     * Syntactic sugar
     * @return the position in the chain, the owner's address and content of the given NFT
     */
    function getCompleteInfo(uint256 tokenId) external view returns(uint256, address, bytes memory);
}
