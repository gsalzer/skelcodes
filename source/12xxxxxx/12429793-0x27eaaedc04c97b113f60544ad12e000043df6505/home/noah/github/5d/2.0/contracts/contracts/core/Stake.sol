pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Token} from "./Token.sol";
import {TokenIdLib} from "../lib/TokenId.sol";

address constant ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
enum NFTStatus {Lockable, Locked, Unlockable, Unlocked}

contract Stake is Ownable {
    struct NFTLockDetails {
        uint256 power;
        uint256 lockPeriod;
    }

    // Power map for each series - { collectionId: { seriesId: power }}.
    mapping(IERC721 => mapping(uint256 => mapping(uint256 => NFTLockDetails)))
        public nftStakeDetails;

    // Record the owner of each token ID.
    mapping(IERC721 => mapping(address => uint256[])) public ownerNFTs;
    mapping(IERC721 => mapping(uint256 => address)) public nftOwner;
    mapping(IERC721 => mapping(uint256 => uint256)) public nftLockTimestamp;
    mapping(IERC721 => mapping(uint256 => uint256)) public nftTokensClaimed;

    Token public token;

    constructor(Token token_) Ownable() {
        token = token_;
    }

    // EVENTS //////////////////////////////////////////////////////////////////

    event NFTLocked(IERC721 indexed nft, uint256 indexed tokenId);
    event NFTRedeemed(
        IERC721 indexed nft,
        uint256 indexed tokenId,
        bytes32 formHash
    );
    event NFTUnlocked(IERC721 indexed nft, uint256 indexed tokenId);

    // PERMISSIONED METHODS ////////////////////////////////////////////////////

    function addNFTLockDetails(
        IERC721 nft,
        uint256 collectionId,
        uint256[] memory seriesIds,
        uint256[] memory powers,
        uint256[] memory lockPeriods
    ) public onlyOwner {
        for (uint256 i = 0; i < seriesIds.length; i++) {
            uint256 currentLockPeriod =
                nftStakeDetails[nft][collectionId][seriesIds[i]].lockPeriod;
            require(
                currentLockPeriod == 0 || lockPeriods[i] <= currentLockPeriod,
                "CANNOT_INCREASE_LOCK_PERIOD"
            );
            nftStakeDetails[nft][collectionId][seriesIds[i]] = NFTLockDetails({
                power: powers[i],
                lockPeriod: lockPeriods[i]
            });
        }
    }

    // USER METHODS ////////////////////////////////////////////////////////////

    function stakeNFTs(IERC721 nft, uint256[] memory tokenIds) public {
        // Optimize accessing power storage in loop.
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftStatus(nft, tokenId) == NFTStatus.Lockable);

            nftOwner[nft][tokenIds[i]] = msg.sender;
            nftLockTimestamp[nft][tokenIds[i]] = block.timestamp;

            ownerNFTs[nft][msg.sender].push(tokenId);
            nft.transferFrom(msg.sender, address(this), tokenId);

            emit NFTLocked(nft, tokenId);
        }
    }

    function claimableTokens(IERC721 nft, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 tokensClaimed = nftTokensClaimed[nft][tokenId];
        uint256 lockTimestamp = nftLockTimestamp[nft][tokenId];

        uint256 collectionId = TokenIdLib.extractCollectionId(tokenId);
        uint256 seriesId = TokenIdLib.extractSeriesId(tokenId);
        NFTLockDetails memory lockDetails =
            nftStakeDetails[nft][collectionId][seriesId];
        uint256 nftPower = lockDetails.power;
        uint256 lockPeriod = lockDetails.lockPeriod;

        uint256 lockProgress = block.timestamp - lockTimestamp;
        if (lockProgress > lockPeriod) {
            lockProgress = lockPeriod;
        }

        uint256 claimableProgress = (nftPower * lockProgress) / lockPeriod;

        if (tokensClaimed >= claimableProgress) {
            return 0;
        }

        uint256 claimable = claimableProgress - tokensClaimed;

        // Sanity check.
        require(
            claimable + tokensClaimed <= nftPower,
            "Stake: invalid claimable amount"
        );

        return claimable;
    }

    function claimTokens(IERC721 nft, uint256[] memory tokenIds) public {
        uint256 powerOwed = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 claimable = claimableTokens(nft, tokenId);

            if (claimable > 0) {
                powerOwed += claimable;
                nftTokensClaimed[nft][tokenId] += claimable;
            }
        }

        if (powerOwed > 0) {
            token.transfer(msg.sender, powerOwed);
        }
    }

    // The following is exposed as a backup. `claimAndUnstakeNFTs` should be
    // used instead.
    function _unstakeNFTs(IERC721 nft, uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftOwner[nft][tokenId] == msg.sender, "NOT_NFT_OWNER");
            require(
                nftStatus(nft, tokenId) == NFTStatus.Unlockable,
                "NOT_UNLOCKABLE"
            );

            nft.transferFrom(address(this), msg.sender, tokenId);

            emit NFTUnlocked(nft, tokenId);
        }
    }

    // Only callable by the owner of the NFTs.
    function claimAndUnstakeNFTs(IERC721 nft, uint256[] memory tokenIds)
        public
    {
        claimTokens(nft, tokenIds);
        _unstakeNFTs(nft, tokenIds);
    }

    function takePayment(address paymentToken, uint256 amount) internal {
        if (paymentToken == ETHEREUM) {
            require(msg.value >= amount, "INSUFFICIENT_ETH_AMOUNT");
            // Refund change.
            payable(msg.sender).transfer(msg.value - amount);
        } else {
            IERC20(paymentToken).transferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
    }

    function withdraw(address withdrawToken) public onlyOwner {
        if (withdrawToken == ETHEREUM) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(withdrawToken).transfer(
                msg.sender,
                IERC20(withdrawToken).balanceOf(address(this))
            );
        }
    }

    // USER METHODS - MULTIPLE NFT CONTRACTS ///////////////////////////////////

    function stakeMultipleNFTs(
        IERC721[] memory nftArray,
        uint256[][] memory tokenIdsArray
    ) public {
        require(nftArray.length == tokenIdsArray.length, "MISMATCHED_LENGTHS");
        for (uint256 i = 0; i < nftArray.length; i++) {
            stakeNFTs(nftArray[i], tokenIdsArray[i]);
        }
    }

    function claimForMultipleNFTs(
        IERC721[] memory nftArray,
        uint256[][] memory tokenIdsArray
    ) public {
        require(nftArray.length == tokenIdsArray.length, "MISMATCHED_LENGTHS");
        for (uint256 i = 0; i < nftArray.length; i++) {
            claimTokens(nftArray[i], tokenIdsArray[i]);
        }
    }

    function unstakeMultipleNFTs(
        IERC721[] memory nftArray,
        uint256[][] memory tokenIdsArray
    ) public {
        require(nftArray.length == tokenIdsArray.length, "MISMATCHED_LENGTHS");
        for (uint256 i = 0; i < nftArray.length; i++) {
            claimAndUnstakeNFTs(nftArray[i], tokenIdsArray[i]);
        }
    }

    // VIEW ////////////////////////////////////////////////////////////////////

    function getNFTStakeDetails(
        IERC721 nft,
        uint256 collectionId,
        uint256 seriesId
    ) public view returns (NFTLockDetails memory) {
        return nftStakeDetails[nft][collectionId][seriesId];
    }

    function nftStatus(IERC721 nft, uint256 tokenId)
        public
        view
        returns (NFTStatus)
    {
        // If there's no owner associated, it's never been locked.
        if (nftOwner[nft][tokenId] == address(0x0)) {
            return NFTStatus.Lockable;
        }

        // If this contract no longer holds the token, it has been unlocked.
        if (nft.ownerOf(tokenId) != address(this)) {
            return NFTStatus.Unlocked;
        }

        uint256 collectionId = TokenIdLib.extractCollectionId(tokenId);
        uint256 seriesId = TokenIdLib.extractSeriesId(tokenId);

        uint256 tokenLockTimestamp = nftLockTimestamp[nft][tokenId];
        uint256 tokenLockPeriod =
            nftStakeDetails[nft][collectionId][seriesId].lockPeriod;

        if (block.timestamp >= tokenLockTimestamp + tokenLockPeriod) {
            return NFTStatus.Unlockable;
        }

        return NFTStatus.Locked;
    }

    function getOwnerNFTs(IERC721 nft, address owner)
        public
        view
        returns (uint256[] memory)
    {
        return ownerNFTs[nft][owner];
    }

    // INTERNAL ////////////////////////////////////////////////////////////////
}

