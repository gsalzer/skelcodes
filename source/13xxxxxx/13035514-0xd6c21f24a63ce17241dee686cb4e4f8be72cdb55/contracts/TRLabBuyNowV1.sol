// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/ITRLabCore.sol";
import "./lib/LibArtwork.sol";
import "./interfaces/IBuyNow.sol";
import "./base/SignerRole.sol";

/// @title Interface for NFT buy-now in a fixed price.
/// @author Joe
/// @notice This is the interface for fixed price NFT buy-now.
contract TRLabBuyNowV1 is IBuyNow, ReentrancyGuard, SignerRole, Ownable, Pausable {
    using SafeERC20 for IERC20;

    /// @dev TRLabCore contract address
    ITRLabCore public trLabCore;
    /// @dev TRLab wallet address
    address public trlabWallet;
    /// @dev artwork id => ArtworkOnSaleInfo
    mapping(uint256 => LibArtwork.ArtworkOnSaleInfo) public artworkOnSaleInfos;
    /// @dev buyer => (artworkId => purchaseCount)
    mapping(address => mapping(uint256 => uint256)) public buyerRecords;

    /// @dev Require that the caller must be an EOA account if not whitelisted.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    /// @dev init contract with TRLabCore contract address and TRLab wallet address
    constructor(ITRLabCore _trlabCore, address _trlabWallet) {
        setTRLabCore(_trlabCore);
        setTRLabWallet(_trlabWallet);
    }

    /// @dev add approved signer for signing purchase signature
    /// @param account address the singer account
    function addSigner(address account) public override onlyOwner {
        _addSigner(account);
    }

    /// @dev remove signer for signing purchase signature
    /// @param account address the singer account
    function removeSigner(address account) public onlyOwner {
        _removeSigner(account);
    }

    /// @dev Sets the trlab nft core contract address.
    /// @param  _trlabCore address the address of the trlab core contract.
    function setTRLabCore(ITRLabCore _trlabCore) public override onlyOwner {
        trLabCore = _trlabCore;
    }

    /// @dev Sets the trlab wallet to receive NFT sale income.
    /// @param  _trlabWallet address the address of the trlab wallet.
    function setTRLabWallet(address _trlabWallet) public override onlyOwner {
        trlabWallet = _trlabWallet;
    }

    /// @dev setup an artwork for sale
    /// @param  _artworkId uint256 the address of the trlab wallet.
    /// @param  _onSaleInfo the ArtworkOnSaleInfo object.
    function putOnSale(uint256 _artworkId, LibArtwork.ArtworkOnSaleInfo memory _onSaleInfo) public override onlyOwner {
        require(_onSaleInfo.endBlock >= _onSaleInfo.startBlock, "endBlock should >= startBlock!");
        require(_onSaleInfo.takeTokenAddress != address(0), "takeTokenAddress cannot be 0x0");
        artworkOnSaleInfos[_artworkId] = _onSaleInfo;
        emit ArtworkOnSale(_artworkId, _onSaleInfo);
    }

    /// @notice buy one NFT token of specific artwork. Needs a proper signature of allowed signer to verify purchase.
    /// @param  _artworkId uint256 the id of the artwork to buy.
    /// @param  v uint8 v of the signature
    /// @param  r bytes32 r of the signature
    /// @param  s bytes32 s of the signature
    function buyNow(
        uint256 _artworkId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override onlyEOA nonReentrant whenNotPaused {
        bytes32 messageHash = keccak256(abi.encode(this, _msgSender(), _artworkId));
        require(_verifySignedMessage(messageHash, v, r, s), "signer should sign buyer address and artwork id!");

        LibArtwork.ArtworkOnSaleInfo memory onSaleInfo = artworkOnSaleInfos[_artworkId];
        _checkOnSaleStatus(onSaleInfo);
        uint256 alreadyBought = buyerRecords[_msgSender()][_artworkId];
        require(alreadyBought < onSaleInfo.purchaseLimit, "you have reached purchase limit!");
        buyerRecords[_msgSender()][_artworkId] = alreadyBought + 1;
        _transferOnSaleToken(onSaleInfo);
        trLabCore.releaseArtworkForReceiver(_msgSender(), _artworkId, 1);
    }

    /// @dev check on-sale if empty, and if both start and end time is valid
    function _checkOnSaleStatus(LibArtwork.ArtworkOnSaleInfo memory onSaleInfo) internal view {
        require(onSaleInfo.takeTokenAddress != address(0), "artwork not on sale!");
        require(onSaleInfo.startBlock <= block.number, "artwork sale not started yet!");
        require(onSaleInfo.endBlock >= block.number, "artwork sale is already ended!");
    }

    /// @dev transfer sale income to trlab wallet account
    function _transferOnSaleToken(LibArtwork.ArtworkOnSaleInfo memory onSaleInfo) internal {
        IERC20(onSaleInfo.takeTokenAddress).safeTransferFrom(_msgSender(), trlabWallet, onSaleInfo.takeAmount);
    }
}

