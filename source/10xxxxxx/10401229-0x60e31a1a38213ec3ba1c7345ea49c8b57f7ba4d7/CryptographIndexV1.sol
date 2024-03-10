// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

/// @author Guillaume Gonnaud 2019
/// @title Cryptoraph Indexer Header
/// @notice Contain all the events emitted by the Cryptoraph Indexer
contract CryptographIndexHeaderV1 {
}

/// @author Guillaume Gonnaud 2019
/// @title Cryptograph Indexer Storage Internal
/// @notice Contain all the storage of the Cryptograph Indexer declared in a way that don't generate getters for Proxy use
contract CryptographIndexStorageInternalV1 {
    bool internal initialized; //Bool to check if the index has been initialized
    address internal factory; //The factory smart contract (proxy) that will publish the cryptographs
    address[] internal cryptographs;
    address[] internal communityCryptographs;
    mapping (address => uint) internal editionSizes; //Set to 0 if unique (not edition)
    mapping (address => uint) internal cryptographType; //0 = Unique, 1 = Edition, 2 = Minting
    uint256 internal indexerLogicCodeIndex; //The index in the Version Control of the logic code

    address internal ERC2665Lieutenant;
}

/// @author Guillaume Gonnaud 2019
/// @title Cryptograph Indexer Storage Public
/// @notice Contain all the storage of the Cryptograph Indexer declared in a way that generates getters for logic use
contract CryptographIndexStoragePublicV1 {
    bool public initialized; //Bool to check if the index has been initialized
    address public factory; //The factory smart contract (proxy) that will publish the cryptographs
    address[] public cryptographs;
    address[] public communityCryptographs;
    mapping (address => uint) public editionSizes; //Set to 0 if unique (not edition)
    mapping (address => uint) public cryptographType; //0 = Unique, 1 = Edition, 2 = Minting
    uint256 public indexerLogicCodeIndex; //The index in the VC of the logic code

    address public ERC2665Lieutenant;
}


