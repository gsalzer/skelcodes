// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./IERC721.sol";
import "./ERC721Holder.sol";

contract KittyTest is ERC721Holder {
    address public kittyCoreAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    KittyCore kittyCore;
    IERC721 kittyNft;

    constructor() public {
        kittyCore = KittyCore(kittyCoreAddress);
        kittyNft = IERC721(kittyCoreAddress);
    }

    function testA1(uint256 tokenId, address toAddress) public {
        kittyNft.transferFrom(msg.sender, toAddress, tokenId);
    }

    function testA2(uint256 tokenId, address toAddress) public {
        kittyCore.transferFrom(msg.sender, toAddress, tokenId);
    }

    function testB1(uint256 tokenId, address toAddress) public {
        kittyNft.transferFrom(msg.sender, toAddress, tokenId);
    }

    function testB2(uint256 tokenId, address toAddress) public {
        kittyCore.transferFrom(msg.sender, toAddress, tokenId);
    }

    function depositA(uint256 tokenId) public {
        kittyNft.transferFrom(msg.sender, address(this), tokenId);
    }

    function depositB(uint256 tokenId) public {
        kittyCore.transferFrom(msg.sender, address(this), tokenId);
    }

    function withdrawA(uint256 tokenId) public {
        kittyNft.transferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawB(uint256 tokenId) public {
        kittyCore.transferFrom(address(this), msg.sender, tokenId);
    }
}

interface KittyCore {
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external;
    function transfer(address _to, uint256 _tokenId) external;
    function getKitty(uint256 _id)
        external
        view
        returns (
            bool,
            bool,
            uint256 _cooldownIndex,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256 _generation,
            uint256
        );
    function kittyIndexToApproved(uint256 index)
        external
        view
        returns (address approved);
}

