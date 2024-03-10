// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

/// @author Guillaume Gonnaud 2019
/// @title Edition Indexer Header
/// @notice Contain all the events emitted by the Edition Indexer
contract EditionIndexerHeaderV1 {
}


/// @author Guillaume Gonnaud 2019
/// @title Edition Indexer Storage Internal
/// @notice Contain all the storage of the Edition Indexer declared in a way that don't generate getters for Proxy use
contract EditionIndexerStorageInternalV1 {
    bool internal initialized; //Bool to check if the indexer have been initialized
    address internal minter; //The address of the minter, the only person allowed to add new cryptographs
    address internal index; //The address of the index, the only address allowed to interact with the publishing functions
    uint256 internal editionSize; //The total amount of cryptographs to be minted in this edition
    address[] internal cryptographs;
}


/// @author Guillaume Gonnaud 2019
/// @title Edition Indexer Storage Public
/// @notice Contain all the storage of the Edition Indexer declared in a way that generate getters for Logic use
contract EditionIndexerStoragePublicV1 {
    bool public initialized; //Bool to check if the index has been initialized
    address public minter; //The address of the minter, only person allowed to add new cryptographs
    address public index; //The address of the index, only address allowed to interact with the publishing functions
    uint256 public editionSize; //The total amount of cryptographs to be minted in this edition
    address[] public cryptographs;
}


