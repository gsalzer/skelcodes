// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./TheCryptographV1.sol";

import "./CryptographFactoryV1.sol";
import "./AuctionHouseV1.sol";
import "./ERC2665LogicV1.sol";
import "./SingleAuctionLogicV1.sol";
import "./CryptographInitiator.sol";

/// @author Guillaume Gonnaud 2019
/// @title TheCryptograph Logic Code
/// @notice Represent a single Cryptograph. Contain provenance, ownership and renatus.
contract TheCryptographLogicV1 is VCProxyData, TheCryptographHeaderV1, TheCryptographStoragePublicV1 {

    /// @notice Generic constructor, empty
    /// @dev This contract is meant to be used in a delegatecall and hence its memory state is irrelevant
    constructor()public{
        //Self intialize (nothing)
    }

    //Modifier for functions that requires to be called only by the Factory
    modifier restrictedToFactory() {
        require(SingleAuctionLogicV1(myAuction).cryFactory() == msg.sender, "Only callable by the factory");
        _;
    }

    /// @notice Init function of TheCryptograph
    /// @param _issue The issue # of this cryptograph
    /// @param _serial The serial # of this cryptograph (only relevant for editions and GGBMA)
    /// @param _official Is it an official or a community cryptograph ?
    /// @param _myAuction The address of our paired auction
    /// @param _cryInitiator The address of the initiator we are gonna grab name and media hash/url from
    /// @param _owner The initial owner. Always 0x0 except for GGBMA minted.
    function initCry(
        uint256 _issue, uint256 _serial, bool _official, address _myAuction, address _cryInitiator, address _owner) external {

        //Can only init if we are either (never init before) or if (we are official, before the auction starting time, and not under renatus)
        require(
            myAuction == address(0) ||
            (
                official &&
                !hasCurrentOwnerMarked &&
                SingleAuctionLogicV1(myAuction).cryFactory() == msg.sender &&
                SingleAuctionLogicV1(myAuction).startTime() > now),
            "This Cryptograph has already been initialized");
        //When renatus is happening, hasCurrentOwnerMarked should be set to true so that perpetual Altruism can't edit again the cryptograph

        //Setting up cryptograph identity related vars
        name = CryptographInitiator(_cryInitiator).name();
        creator = CryptographInitiator(_cryInitiator).creator();

        emit Named(name);

        mediaHash = CryptographInitiator(_cryInitiator).mediaHash();
        emit MediaHash(mediaHash);

        mediaUrl = CryptographInitiator(_cryInitiator).mediaUrl();
        emit MediaUrl(mediaUrl);

        serial = _serial;
        issue = _issue;

        official = _official;

        //Setting up initial owner (nobody EXCEPT GGBMA minting)
        owner = _owner;

        //Linking the auction
        myAuction = _myAuction;

    }

    /// @notice Set the media hash of the Cryptograph
    /// @dev Advanced requirement checks should be done on the factory side
    /// @param _mediaHash A string containing the media hash
    function setMediaHash(string calldata _mediaHash) external restrictedToFactory() {
        mediaHash = _mediaHash;
        emit MediaHash(_mediaHash);
    }

    /// @notice Set the media url of the Cryptograph
    /// @dev Advanced requirement checks should be done on the factory side
    /// @param _mediaUrl A string containing the media url
    function setMediaUrl(string calldata _mediaUrl)external restrictedToFactory() {
        mediaUrl = _mediaUrl;
        emit MediaUrl(_mediaUrl);
    }

    /// @notice Transfer ownership of the token
    /// @dev only callable by the associated GBM auction instance
    /// @param _newOwner The address of the account to become the new owner
    function transfer(address _newOwner) external {
        require(msg.sender == myAuction, "The auction is the only way to set a new owner");
        emit Transferred(owner, _newOwner);
        owner = _newOwner;
        hasCurrentOwnerMarked = false;

        //Resetting renatus timer
        lastOwnerInteraction = now;
        renatusTimeStamp = 0;
    }

    /// @notice Mark a cryptograph
    /// @dev only callable by the current owner if he has not done it since he gained ownership
    /// @param _mark A 3 Character long string containing the mark
    function mark(string calldata _mark) external {
        require(msg.sender == owner, "Only the owner can set a mark on a cryptograph");
        require(!hasCurrentOwnerMarked, "The cryptograph has already been marked by the owner");
        require(bytes(_mark).length <= 3, "You can only inscribe at most 3 characters at a time"); //In Utf8, strlenght <= bytelength.

        hasCurrentOwnerMarked = true; //Setting the current owner has having marked

        marks.push(_mark); //Inscribing the mark
        markers.push(owner); //Associating the owner

        emit Marked(owner, _mark); //Emitting the event

        //Resetting renatus timer
        lastOwnerInteraction = now;
        renatusTimeStamp = 0;
    }

    /// @notice Prevent burning cryptographs by putting them back to auctions if abandoned by their owners
    /// @dev If called by the owner, and ERC-2665 operator of perpetual altruism refresh ownership for 5 years
    function renatus() external {
        if (msg.sender == owner ||
            msg.sender == myAuction ||
            msg.sender == SingleAuctionLogicV1(myAuction).publisher() ||
            msg.sender == AuctionHouseStoragePublicV1(SingleAuctionLogicV1(myAuction).auctionHouse()).ERC2665Lieutenant()) {
            lastOwnerInteraction = now; //If the owner/operator/Pa call, reset the renatus call
            renatusTimeStamp = 0;
            emit Renatus(0);
        } else {
            require(now >= lastOwnerInteraction + 60 * 60 * 24 * 366 * 5, "Five years have not yet elapsed since last owner interaction");

            // Set up a 31 day deadline for the owner to claim their Cryptograph again
            if (renatusTimeStamp == 0) {
                renatusTimeStamp = now + 60 * 60 * 24 * 31;
                //Emit the event
                emit Renatus(renatusTimeStamp);
            } else {
                require(now > renatusTimeStamp, "31 days since renatus was called have not elapsed yet");

                SingleAuctionLogicV1(myAuction).renatus();

                //Notify the ERC2665 contract
                ERC2665LogicV1(AuctionHouseStoragePublicV1(SingleAuctionLogicV1(myAuction).auctionHouse()).ERC2665Lieutenant()).triggerRenatus();
                hasCurrentOwnerMarked = true; //Prevent publisher meddling
            }
        }
    }

}

