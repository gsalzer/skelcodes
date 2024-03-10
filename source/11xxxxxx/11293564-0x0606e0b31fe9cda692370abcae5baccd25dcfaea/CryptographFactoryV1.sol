// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

/// @author Guillaume Gonnaud 2019
/// @title Factory Header
/// @notice Contain all the events emitted by the factory
contract CryptographFactoryHeaderV1 {
    event CryptographCreated(uint256 indexed cryptographIssue, address indexed cryptographAddress, bool indexed official);
    event CryptographEditionAdded(uint256 indexed cryptographIssue, uint256 indexed editionSize, bool indexed official);
    event CryptographEditionMinted(uint256 indexed cryptographIssue, uint256 indexed editionIssue, address cryptographAddress, bool indexed official);
}


/// @author Guillaume Gonnaud 2019
/// @title Factory Storage Internal
/// @notice Contain all the storage of the Factory declared in a way that does not generate getters for Proxy use
contract CryptographFactoryStorageInternalV1 {

    bool internal initialized; //A bool controlling if we have been initialized or not

    address internal officialPublisher; //The address that is allowed to publish the official (i.e. non-community) cryptographs

    /*
    ==================================================
                    Linking section
    ==================================================
    Those are the addresses of other smart contracts in the ecosystem and relevant value to them
    */
    address internal targetVC; //Address of the version control that the Cryptograph should use (potentially different than ours)
    address internal targetAuctionHouse; //Address of the Auction house used by Cryptograph
    address internal targetIndex; //Address of the Cryptograph library storing both fan made and public cryptographs

    // DO NOT PUT THE CRYPTOGRAPH PROXY CODE ADDRESS IN HERE, it needs to be in the logic code of the factory
    // IDEM FOR SINGLE AUCTION PROXY CODE
    uint256 internal targetCryLogicVersion; //Which version of the logic code in the Version Control array the cryptographs should use
    //Which version of the logic code in the Version Control array the Single Auction should use
    uint256 internal targetAuctionLogicVersion;
    //Which version of the logic code in the Version Control array the Single Auction Bid should use
    uint256 internal targetAuctionBidLogicVersion;
    //Which version of the logic code in the Version Control array the Minting Auction should use
    uint256 internal targetMintingAuctionLogicVersion;

    //Actual data storage section
    mapping (address => uint256) internal mintingAuctionSupply; //How much token can be created by each MintingAuction

    //Are Community cryptographs allowed to be minted ?
    bool internal communityMintable;

}


/// @author Guillaume Gonnaud 2019
/// @title Factory Storage Public
/// @notice Contain all the storage of the Factory declared in a way that generates getters for Logic use
contract CryptographFactoryStoragePublicV1 {

    bool public initialized; //A bool controlling if we have been initialized or not

    address public officialPublisher; //The address that is allowed to publish the non-community cryptographs

    /*
    ==================================================
                    Linking section
    ==================================================
    Those are the addresses of other smart contracts in the ecosystem and the relevant Version Control index value to them
    */
    address public targetVC; //Address of the version control the cryptographs should use
    address public targetAuctionHouse; //Address of the Auction house used by cryptograph
    address public targetIndex; //Address of the Cryptograph library storing both fan made and public cryptographs

    uint256 public targetCryLogicVersion; //Which version of the logic code in the Version Control array the cryptographs should use
    uint256 public targetAuctionLogicVersion; //Which version of the logic code in the Version Control array the Single Auction should use
    //Which version of the logic code in the Version Control array the Single Auction Bid should use
    uint256 public targetAuctionBidLogicVersion;
    //Which version of the logic code in the Version Control array the Minting Auction should use
    uint256 public targetMintingAuctionLogicVersion;

    //Actual data storage section
    mapping (address => uint256) public mintingAuctionSupply; //How much token can be created by each MintingAuction

    //Are Community cryptographs allowed to be minted ?
    bool public communityMintable;
}
