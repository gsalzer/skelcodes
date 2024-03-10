// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import { ERC721Upgradeable as ERC721 } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { OwnableUpgradeable as Ownable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { CountersUpgradeable as Counters } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract LotteryNFT is Initializable, ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (uint256 => uint8[4]) public lotteryInfo;
    mapping (uint256 => uint256) public lotteryAmount;
    mapping (uint256 => uint256) public issueIndex;
    mapping (uint256 => bool) public claimInfo;

    function initialize() public initializer {
        __Ownable_init();
        __ERC721_init("UniTrade Lottery Ticket", "ULT");
    }

    function newLotteryItem(address player, uint8[4] memory _lotteryNumbers, uint256 _amount, uint256 _issueIndex)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        lotteryInfo[newItemId] = _lotteryNumbers;
        lotteryAmount[newItemId] = _amount;
        issueIndex[newItemId] = _issueIndex;
        // claimInfo[newItemId] = false; default is false here
        // _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function getLotteryNumbers(uint256 tokenId) external view returns (uint8[4] memory) {
        return lotteryInfo[tokenId];
    }
    function getLotteryAmount(uint256 tokenId) external view returns (uint256) {
        return lotteryAmount[tokenId];
    }
    function getLotteryIssueIndex(uint256 tokenId) external view returns (uint256) {
        return issueIndex[tokenId];
    }
    function claimReward(uint256 tokenId) external onlyOwner {
        claimInfo[tokenId] = true;
    }
    function multiClaimReward(uint256[] memory tokenIds) external onlyOwner {
        for (uint i = 0; i < tokenIds.length; i++) {
            claimInfo[tokenIds[i]] = true;
        }
    }
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
    function getClaimStatus(uint256 tokenId) external view returns (bool) {
        return claimInfo[tokenId];
    }
}

