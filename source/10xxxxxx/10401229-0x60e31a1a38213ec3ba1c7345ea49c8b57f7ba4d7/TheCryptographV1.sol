// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";

/// @author Guillaume Gonnaud 2019
/// @title TheCryptograph Header
/// @notice Contain all the events emitted by TheCryptograph
contract TheCryptographHeaderV1 {
    event Named(string name);
    event MediaHash(string mediaHash);
    event MediaUrl(string mediaUrl);
    event Transferred(address indexed previousOwner, address indexed newOwner);
    event Marked (address indexed Marker, string indexed Mark);
    event Renatus(uint256 endtime);
}


/// @author Guillaume Gonnaud 2019
/// @title TheCryptograph Storage Internal
/// @notice Contain all the storage of TheCryptograph declared in a way that don't generate getters for Proxy use
contract TheCryptographStorageInternalV1 {

    /*
    ==================================================
                    Identity Section
    ==================================================
    */
    string internal name; //The name of this cryptograph
    string internal creator; //The creator of this cryptograph
    string internal mediaHash; //The hash of the cryptograph media
    string internal mediaUrl; //An url where the cryptograph media is accessible
    uint256 internal serial; //The serial number of this cryptograph (position in the index)
    uint256 internal issue; //The numbered minting of this specific cryptograph.
    bool internal hasCurrentOwnerMarked; //Each subsequent owner can only leave its mark once
    string[] internal marks; //Each owner can leave its mark on the cryptograph
    address[] internal markers; //List of owners that have left a mark

    /*
    ==================================================
                        Ownership section
    ==================================================
    */
    address internal owner; //The current owner of the cryptograph

    /*
    ==================================================
                    Auction Section
    ==================================================
    */
    address internal myAuction; //Address of the running auction associated with this Cryptograph
    bool internal official; //Are we an official cryptograph ?

    /*
    ==================================================
                    Renatus Section
    ==================================================
    */
    uint256 internal lastOwnerInteraction; //When was the last time the owner interacted with the cryptograph ?
    uint256 internal renatusTimeStamp; //When was the last time someone wanted to check if the owner was still owning it's private key ?

}


/// @author Guillaume Gonnaud 2019
/// @title TheCryptograph Storage Public
/// @notice Contain all the storage of TheCryptograph declared in a way that generates getters for Logic use
contract TheCryptographStoragePublicV1 {

    /*
    ==================================================
                    Identity Section
    ==================================================
    */
    string public name; //The name of this cryptograph
    string public creator; //The creator of this cryptograph
    string public mediaHash; //The hash of the cryptograph media
    string public mediaUrl; //An url where the cryptograph media is accessible
    uint256 public serial; //The serial number of this cryptograph (position in the index)
    uint256 public issue;
    bool public hasCurrentOwnerMarked; //Each subsequent owner can only leave its mark once
    string[] public marks; //Each owner can leave its mark on the cryptograph
    address[] public markers; //List of owners that have left a mark

    /*
    ==================================================
                        Ownership Section
    ==================================================
    */
    address public owner; //The current owner of the cryptograph

    /*
    ==================================================
                    Auction Section
    ==================================================
    */
    address public myAuction; //Address of the running auction associated with this Cryptograph
    bool public official; //Are we an official cryptograph ?

    /*
    ==================================================
                    Renatus Section
    ==================================================
    */
    uint256 public lastOwnerInteraction; //When was the last time the owner interacted with the cryptograph ?
    uint256 public renatusTimeStamp; //When was the last time someone wanted to check if the owner was still owning it's private key ?

}


