// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChilliSwap {

//    enum CURRENCY{ ETH, TOKEN}

    struct Artwork {
        uint256 date;
        address creator;
        string artwork;
        string metadata;
        uint256 royalty;
    }



    function mintNFT( address recipient, string memory metadata,  string memory artwork,  uint256 royalty) external returns (uint256);
    function mintAndApproveNFT( address recipient, string memory metadata,  string memory artwork,  uint256 royalty) external returns (uint256);

    function burnNFT(uint256 tokenId)  external  returns(bool);

    function getArtwork(uint256 tokenId) external view returns (Artwork memory);
  
    function isCreator(address creator)  external view returns(bool);


    function addCreator(address creator)  external returns(bool);    
    function removeCreator(address creator)  external returns(bool);

    function setNftMarketContract(address marketContract) external  returns(bool);


     event Mint(address indexed to, uint256  tokenId, string artwork);


}

