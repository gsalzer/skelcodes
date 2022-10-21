// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./EditionIndexerV1.sol";

/// @title Edition Indexer Logic Contract
/// @author Guillaume Gonnaud
/// @notice Provides the logic code for publishing and interacting with editions, nested into the Cryptograph Indexer
/// @dev This contract and its functions should be called by the relevant proxy smart contract only
contract EditionIndexerLogicV1 is VCProxyData, EditionIndexerHeaderV1, EditionIndexerStoragePublicV1  {

    /// @notice Generic constructor, empty
    /// @dev This contract is meant to be used in a delegatecall and hence its memory state is irrelevant
    constructor() public
    {
        //Self intialize (nothing)
    }

    //Modifier for functions that require to be called only by the index
    modifier restrictedToIndex(){
        require((msg.sender == index), "Only the cryptograph index smart contract can call this function");
        _;
    }

    /// @notice Init function of the Indexer, starting at index 1
    /// @dev Callable only once after instanciation
    /// @param _index The address of the parent, main indexer
    /// @param _minter The address of the minter for this edition
    /// @param _editionSize The maximum number of cryptographs in this edition
    /// @return true
    function init(address _index, address _minter, uint256 _editionSize) external returns(bool){
        require(!initialized, "This Edition Indexer has already been initialized");
        index = _index;
        minter = _minter;
        editionSize = _editionSize;
        initialized = true;
        cryptographs.push(address(0x0)); //There is no cryptograph edition with serial 0
        return true;
    }

    /// @notice Init function of the Indexer, starting at index 0
    /// @dev Callable only once after instanciation
    /// @param _index The address of the parent, main indexer
    /// @param _minter The address of the minter for this edition
    /// @param _editionSize The maximum number of cryptographs in this edition
    /// @return true
    function init0(address _index, address _minter, uint256 _editionSize) external returns(bool){
        require(!initialized, "This Edition Indexer has already been initialized");
        index = _index;
        minter = _minter;
        editionSize = _editionSize;
        initialized = true;
        return true;
    }

    /// @notice Insert a cryptograph in the array and return the new index position
    /// @dev Callable only by the index
    /// @param _cryptograph The address of the inserted cryptograph
    /// @param _minter The address of the minter for this cryptograph
    /// @return The new position in the array
    function insertACryptograph(address _cryptograph, address _minter) external restrictedToIndex() returns(uint){
        require(cryptographs.length <= editionSize, "The full amount of Cryptographs for this edition has been published");
        require(_minter == minter, "Only the publisher can mint new Cryptographs for this edition");
        cryptographs.push(_cryptograph);
        return (cryptographs.length - 1); //Inserting the cryptograph and returning the position in the array
    }

    /// @notice Insert a cryptograph in the array at a specific position
    /// @dev Callable only by the index. Must be smaller than edition size. HAS A LOOP.
    /// @param _cryptograph The address of the inserted cryptograph
    /// @param _index The desired position
    function insertACryptographAt(address _cryptograph, uint256 _index) external restrictedToIndex(){

        if(cryptographs.length <= _index){
            while(cryptographs.length <= _index){
                cryptographs.push();
            }
        }
        cryptographs[_index] = _cryptograph; //Inserting the cryptograph
    }

}


