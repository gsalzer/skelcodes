// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

/// @author Guillaume Gonnaud 2019
/// @title Senate Header
/// @notice Contain all the events emitted by the Senate
contract SenateHeaderV1 {
    event AddedLogicCodeToVC(address law); //A new logic code address (law) was added to the available pool
    event RemovedLogicCodeToVC(address law); //A logic code address (law) was removed from the available pool
    event NewLawProposal(uint256 lawIndex, address law, uint256 enactionTime, bool revokeLaw, bool stateOfEmergency); //A new law proposal to vote on
    event EnactProposal(uint256 lawIndex, address law, uint256 enactionTime, bool revokeLaw, bool stateOfEmergency); //The lawmaker applied a proposal
    event Voted(bool vote, uint256 lawIndex, uint256 issueNumber, uint256 SerialNumber); //Emitted when a token holder vote on a low
    event DemocracyOn(); //Enable voting before adding new laws
    event DemocracyOff(); //Give back the ability to the lawmaker to add any law without a vote
}


/// @author Guillaume Gonnaud
/// @title Senate Storage Internal
/// @notice Contain all the storage of the Senate declared in a way that does not generate getters for Proxy use
contract SenateStorageInternalV1 {

    bool internal democracy; //A bool controlling if address addition/removal is subject to vote
    mapping (address => bool) internal laws; //The list of allowed smart contract addresses for use in the Version Control
    address internal lawmaker; //Address allowed to sumbmit new address to be voted upon.
    address[] internal lawPropositions; //List of proposed laws to be voted upon
    address internal cryptographIndex; //The cryptograph index address
    uint256 internal totalLaws; //The total number of published laws

}


/// @author Guillaume Gonnaud
/// @title Senate Storage External
/// @notice Contain all the storage of the Senate declared in a way that generates getters for Logic Code use
contract SenateStorageExternalV1 {

    bool public democracy; //A bool controlling if address addition/removal is subject to vote
    mapping(address => bool) public laws; //The list of allowed smart contract addresses for use in the VC
    address public lawmaker; //Address allowed to sumbmit new address to be voted upon.
    address[] public lawPropositions; //List of proposed laws to be voted upon
    address public cryptographIndex; //The cryptograph index address
    uint256 public totalLaws; //The total number of published laws
}


