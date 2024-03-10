// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./CryptographIndexV1.sol";
import "./EditionIndexerProxiedV1.sol";
import "./EditionIndexerLogicV1.sol";
import "./ERC2665LogicV1.sol";

///@title Cryptograph Index Logic Contract
///@author Guillaume Gonnaud
///@notice Provide the logic code related to remembering the address of all the published cryptographs. Cast this contract on the proxy.
///@dev This contract and its functions should be called by the relevant proxy smart contract only
contract CryptographIndexLogicV1 is VCProxyData, CryptographIndexHeaderV1, CryptographIndexStoragePublicV1  {

    /// @notice Generic constructor, empty
    /// @dev This contract is meant to be used in a delegatecall and hence it's memory state is irrelevant
    constructor() public
    {
        //Self intialize (nothing)
    }

    //Modifier for functions that requires to be called only by the cryptograph factory
    modifier restrictedToFactory(){
        require((msg.sender == factory), "Only the cryptograph factory smart contract can call this function");
        _;
    }

    /// @notice Init function of the Index
    /// @dev Callable only once after deployment
    /// @param _factory The address of the CryptographFactory Instance
    /// @param _indexerLogicCodeIndex The index in the VC of editionIndexers logic code
    /// @param _ERC2665Lieutenant The address of the ERC721 Instance
    function init(address _factory, uint256 _indexerLogicCodeIndex, address _ERC2665Lieutenant) external returns(bool){
        require(!initialized, "The cryptograph index has already been initialized");
        factory = _factory;
        indexerLogicCodeIndex = _indexerLogicCodeIndex;
        initialized = true;
        cryptographs.push(address(0x0));
        communityCryptographs.push(address(0x0));
        ERC2665Lieutenant = _ERC2665Lieutenant;
        return true;
    }


    /// @notice Insert a cryptograph in the array and return the new index position
    /// @dev Only callable by Factory
    /// @param _cryptograph The address of the cryptograph to insert in the index
    /// @return (uint) The new index position in the cryptograph array
    function insertACryptograph(address _cryptograph) external restrictedToFactory() returns(uint){

        //Update the ERC2665
        ERC2665LogicV1(ERC2665Lieutenant).MintACryptograph(_cryptograph);
        cryptographs.push(_cryptograph);
        return (cryptographs.length - 1); //Inserting the cryptograph and returning the position in the array
    }


    /// @notice Insert a community cryptograph in the array and return the new index position
    /// @dev Only callable by Factory
    /// @param _communityCryptograph The address of the community cryptograph to insert in the index
    /// @return (uint) The new index position in the community cryptograph array
    function insertACommunityCryptograph(address _communityCryptograph) external restrictedToFactory() returns(uint){

        //Update the ERC2665
        ERC2665LogicV1(ERC2665Lieutenant).MintACryptograph(_communityCryptograph);

        communityCryptographs.push(_communityCryptograph);
        return (communityCryptographs.length - 1); //Inserting the community cryptograph and returning new position in array
    }


    /// @notice Create a new cryptograph edition and return the new index position
    /// @dev Only callable by Factory
    /// @param _minter The address of the user wallet that will have the responsability to mint all the editions
    /// @param _editionSize The maximum number of cryptograph that can be minted in the edition
    /// @return (uint) The new index position in the cryptograph array
    function createAnEdition(address _minter, uint256 _editionSize) external restrictedToFactory() returns(uint){
        require(_minter != address(0) && _editionSize != 0,
            "Minter address and edition size must be greater than 0"
        );

        //Create a new indexer for the edition
        EditionIndexerProxiedV1 _proxied = new EditionIndexerProxiedV1(indexerLogicCodeIndex, vc);

        //Initializing the indexer
        EditionIndexerLogicV1(address(_proxied)).init(address(this), _minter, _editionSize);

        //Adding the indexer to the mapping
        editionSizes[address(_proxied)] = _editionSize;

        //Indicate our type as edition
        cryptographType[address(_proxied)] = 1;

        //Inserting the edition and returning the position in the array
        cryptographs.push(address(_proxied));
        return (cryptographs.length - 1);
    }


    /// @notice Create a new cryptograph edition starting at 0 and return the new index position
    /// @dev Only callable by Factory
    /// @param _minter The address of the user wallet that will have the responsability to mint all the editions
    /// @param _editionSize The maximum number of cryptograph that can be minted in the edition
    /// @return (uint) The new index position in the cryptograph array
    function createAGGBMA(address _minter, uint256 _editionSize) external restrictedToFactory() returns(uint){
        require(_minter != address(0) && _editionSize != 0,
            "Minter address and edition size must be greater than 0"
        );

        //Create a new indexer for the edition
        EditionIndexerProxiedV1 _proxied = new EditionIndexerProxiedV1(indexerLogicCodeIndex, vc);

        //Initializing the indexer
        EditionIndexerLogicV1(address(_proxied)).init0(address(this), _minter, _editionSize+1);

        //Adding the indexer to the mapping
        editionSizes[address(_proxied)] = _editionSize;

        //Indicate our type as edition
        cryptographType[address(_proxied)] = 1;

        //Inserting the edition and returning the position in the array
        cryptographs.push(address(_proxied));
        return (cryptographs.length - 1);
    }


    /// @notice Create a new community edition and return the new index position
    /// @dev Only callable by Factory
    /// @param _minter The address of the user wallet that will have the responsability to mint all the editions
    /// @param _editionSize The maximum number of community cryptograph that can be minted in the edition
    /// @return (uint) The new index position in the cryptograph community array
    function createACommunityEdition(address _minter, uint256 _editionSize) external restrictedToFactory() returns(uint){
        //Create a new indexer for the edition
        EditionIndexerProxiedV1 _proxied = new EditionIndexerProxiedV1(indexerLogicCodeIndex, vc);

        //Initializing the indexer
        EditionIndexerLogicV1(address(_proxied)).init(address(this), _minter, _editionSize);

        //Adding the indexer to the mapping
        editionSizes[address(_proxied)] = _editionSize;

        //Indicate our type as edition
        cryptographType[address(_proxied)] = 1;

        //Inserting the edition and returning the position in the array
        communityCryptographs.push(address(_proxied));
        return (communityCryptographs.length - 1);
    }


    /// @notice Create a new cryptograph community edition starting at 0 and return the new index position
    /// @dev Only callable by Factory
    /// @param _minter The address of the user wallet that will have the responsability to mint all the editions
    /// @param _editionSize The maximum number of cryptograph that can be minted in the edition
    /// @return (uint) The new index position in the community cryptograph array
    function createACommunityGGBMA(address _minter, uint256 _editionSize) external restrictedToFactory() returns(uint){
        //Create a new indexer for the edition
        EditionIndexerProxiedV1 _proxied = new EditionIndexerProxiedV1(indexerLogicCodeIndex, vc);

        //Initializing the indexer
        EditionIndexerLogicV1(address(_proxied)).init0(address(this), _minter, _editionSize+1); //One more for the prototype

        //Adding the indexer to the mapping
        editionSizes[address(_proxied)] = _editionSize;

        //Indicate our type as edition
        cryptographType[address(_proxied)] = 1;

        //Inserting the edition and returning the position in the array
        communityCryptographs.push(address(_proxied));
        return (communityCryptographs.length - 1);
    }


    /// @notice Mint an Edition Cryptograph
    /// @dev Only callable by Factory
    /// @param _minter The address of the user wallet that is minting the cryptograph
    /// @param _cryptographIssue The issue # of the edition we are minting a new member of
    /// @param _isOfficial Is it a community edition or not ?
    /// @param _cryptograph The address of the cryptograph we are inserting in the edition indexer
    /// @return (uint) The serial of the newly inserted cryptograph
    function mintAnEdition(
        address _minter,
        uint256 _cryptographIssue,
        bool _isOfficial,
        address _cryptograph
    ) external restrictedToFactory() returns(uint){


        //Update the ERC2665
        ERC2665LogicV1(ERC2665Lieutenant).MintACryptograph(_cryptograph);

        //Indicate our type as edition
        cryptographType[_cryptograph] = 1;

        if(_isOfficial){
            uint256 edIdx = EditionIndexerLogicV1(cryptographs[_cryptographIssue]).insertACryptograph(_cryptograph, _minter);
            return edIdx;
        } else {
            uint256 edIdx = EditionIndexerLogicV1(communityCryptographs[_cryptographIssue]).insertACryptograph(_cryptograph, _minter);
            return edIdx;
        }
    }


    /// @notice Mint an Edition Cryptograph with a specific serial
    /// @dev Only callable by Factory
    /// @param _cryptographIssue The issue # of the edition we are minting a new member of
    /// @param _cryptographSerial The serial # we want to insert in the edition
    /// @param _isOfficial Is it a community edition or not ?
    /// @param _cryptograph The address of the cryptograph we are inserting in the edition indexer
    function mintAnEditionAt(
        uint256 _cryptographIssue,
        uint256 _cryptographSerial,
        bool _isOfficial,
        address _cryptograph
    ) external restrictedToFactory(){


        //Update the ERC2665
        ERC2665LogicV1(ERC2665Lieutenant).MintACryptograph(_cryptograph);

        //Indicate our type as edition
        cryptographType[_cryptograph] = 1;

        if(_isOfficial){
            EditionIndexerLogicV1(cryptographs[_cryptographIssue]).insertACryptographAt(_cryptograph, _cryptographSerial);
        } else {
            EditionIndexerLogicV1(communityCryptographs[_cryptographIssue]).insertACryptographAt(_cryptograph, _cryptographSerial);
        }
    }


    /// @notice Return the address of a Cryptograph using it's parameters
    /// @dev You can then cast this address as a Cryptograph to recover the single auction associated
    /// @param _cryptographIssue The issue # of the Cryptograph
    /// @param _isOfficial True if official Cryptograph, false if community Cryptograph
    /// @param _editionSerial The edition serial # of the Cryptograph. Ignored if the Cryptograph is not an edition
    /// @return The address of the grabbed cryptograph
    function getCryptograph(uint256 _cryptographIssue, bool _isOfficial, uint256 _editionSerial) external view returns(address){
        if(_isOfficial){
            if(cryptographType[address(cryptographs[_cryptographIssue])] == 0){
                //We are unique
                return(address(cryptographs[_cryptographIssue]));
            } else {
                //We are an edition/GGBMA
                return(address(EditionIndexerLogicV1(cryptographs[_cryptographIssue]).cryptographs(_editionSerial)));
            }
        } else {
            if(cryptographType[address(communityCryptographs[_cryptographIssue])] == 0){
               //We are unique
                return(address(communityCryptographs[_cryptographIssue]));
            } else {
                //We are an edition/GGBMA
                return(address(EditionIndexerLogicV1(communityCryptographs[_cryptographIssue]).cryptographs(_editionSerial)));
            }
        }
    }

}


