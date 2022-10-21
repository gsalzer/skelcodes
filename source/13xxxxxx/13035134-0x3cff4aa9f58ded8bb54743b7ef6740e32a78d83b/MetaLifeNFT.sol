//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract MetaLife is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event SketchSelled(uint256 tokenId);

    Sketch[] public sketches;

    struct Sketch {
        uint256 price;
        bool onSale;
        string tokenURI;
        address owner;
    }

    constructor() public ERC721("MetaLife", "LIFE") {}

    function mintNFT(address recipient, string memory tokenURI)
        public
        returns (uint256)
    {
        Sketch memory _sketch = Sketch({
            price: 0,
            onSale: false,
            tokenURI: tokenURI,
            owner: msg.sender
        });

        sketches.push(_sketch);

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        _tokenIds.increment();

        return newItemId;
    }

    function transactionNFT(address to, uint256 tokenId) external payable {
        address payable owner = address(uint160(ownerOf(tokenId)));
        require(owner != msg.sender);
        require(owner != address(0));

        Sketch storage _sketch = sketches[tokenId];
        require(msg.value >= _sketch.price);
        require(_sketch.onSale == true);

        approve(to, tokenId);
        owner.transfer(_sketch.price);

        safeTransferFrom(owner, to, tokenId);
        _sketch.price = 0;
        _sketch.onSale = false;
        _sketch.owner = to;
    }

    function sellNFT(address marketContract, uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender);
        Sketch storage _sketch = sketches[tokenId];
        _sketch.price = price;
        _sketch.onSale = true;

        setApprovalForAll(marketContract, true);

        emit SketchSelled(tokenId);
    }

    function getSketch(uint256 tokenId)
        public
        view
        returns (
            Sketch memory _sketch
        ) {
            Sketch memory sketch = sketches[tokenId];
            return sketch;
        }
}
