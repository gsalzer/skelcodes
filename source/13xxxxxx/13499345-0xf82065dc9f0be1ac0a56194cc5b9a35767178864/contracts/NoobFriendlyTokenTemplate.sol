//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

struct BaseSettings {
    string name;
    string symbol;
    address[] payees;
    uint[] shares;
    uint32 typeOfNFT;
    uint32 maxSupply;
}

struct BaseSettingsInfo {
    string name;
    string symbol;
    uint32 typeOfNFT;
    uint32 maxSupply;    
}

interface GeneratorInterface {
    function slottingFee() external view returns (uint);
    function genNFTContract(address, BaseSettings calldata) external returns (address);
}

interface TemplateInterface {
    function owner() external returns (address);
    function transferOwnership(address newOwner) external;
}

/**
 @author Justa Liang
 @notice Template of NFT contract
 */
abstract contract NoobFriendlyTokenTemplate is Ownable, PaymentSplitter, ERC721 {

    struct Settings {
        uint32 maxSupply;
        uint32 totalSupply;
        uint32 maxPurchase;
        uint32 typeOfNFT;
        uint128 startTimestamp;
    }

    /// @notice Template settings
    Settings public settings;
    
    /// @notice Prefix of tokenURI
    string public baseURI;

    /// @notice Whether contract is initialized
    bool public isInit;

    /// @dev Setup type and max supply 
    constructor(
        uint32 typeOfNFT_,
        uint32 maxSupply_
    ) {
        settings.typeOfNFT = typeOfNFT_;
        settings.maxSupply = maxSupply_;
        isInit = false;
    }

    /// @dev Make the contract to initialized only once
    modifier onlyOnce() {
        require(!isInit, "init already");
        isInit = true;
        _;
    }

    /// @notice Mint token with ID exceeding max supply
    function specialMint(
        address recevier,
        uint tokenId
    ) external onlyOwner {
        require(
            tokenId > settings.maxSupply,
            "special mint error"
        );
        _safeMint(recevier, tokenId);
    }
}
