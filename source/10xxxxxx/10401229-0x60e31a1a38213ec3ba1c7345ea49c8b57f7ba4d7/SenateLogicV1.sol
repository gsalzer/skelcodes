// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./SenateV1.sol";
import "./CryptographIndexLogicV1.sol";
import "./TheCryptographLogicV1.sol";

/// @author Guillaume Gonnaud
/// @title Senate Logic Code
/// @notice This contract is used by the Version Control to determine what smart contracts are allowed to use in the ecosystem. It's logic code, cast a proxy with it.
contract SenateLogicV1 is VCProxyData, SenateHeaderV1, SenateStorageExternalV1  {

    /// @notice Generic constructor, empty
    /// @dev This contract is meant to be used in a delegatecall and hence its memory state is irrelevant
    constructor() public
    {
        //Self intialize (nothing)
    }

    //Modifier for functions that requires to be called only by the lawmaker
    modifier restrictedToLawmaker(){
        require(msg.sender == lawmaker, "Only the lawmaker can call this function");
        _;
    }

    /// @notice Init function of the Senate
    /// @param _cryptographIndex The address of the cryptograph index that we will use to lookup owners
    function init(address _cryptographIndex) external {
        require (cryptographIndex == address(0x0), "The senate has already been initialized");
        cryptographIndex = _cryptographIndex;
    }

    /// @notice The Version Control must ask the senate (using this function) if an address is authorized before setting it in code
    /// @dev New addresses are voted in by cryptographs owners
    /// @param _candidateAddress The serial of the Cryptograph you want to peek highest bid on
    /// @return If the address can be used in the Version Control
    function isAddressAllowed(address _candidateAddress) external view returns(bool){
        bool retour = laws[_candidateAddress];
        return retour;
    }

    /// @notice Forcefully add or remove an address from the addresses the VC can use.
    /// @dev https://en.wikipedia.org/wiki/Article_49_of_the_French_Constitution
    /// @param _candidateAddress The serial of the Cryptograph you want to peek highest bid on
    /// @param _allowed A bool indicating _candidateAddress use for the Version Control. True if the address is to be allowed, False if disallowed
    function quaranteNeufTrois(address _candidateAddress, bool _allowed) external restrictedToLawmaker() {
        require(!democracy, "Democracy is enforced, new addresses must be subject to approval by the senate");
        laws[_candidateAddress] = _allowed;
        if(!_allowed){ //Are we deleting a law ?
                laws[_candidateAddress] = false;
                emit RemovedLogicCodeToVC(_candidateAddress); //emit the event
            } else { //We are adding a law
                laws[_candidateAddress] = true;
                emit AddedLogicCodeToVC(_candidateAddress); //emit the event
            }
    }

    /// @notice Set the senate to democratic : new laws must be voted upon
    function powerToThePeople() external restrictedToLawmaker(){
        require(!democracy, "Democracy is already in place");
        democracy = true; //https://youtu.be/T-TGPhVC0AE?t=11
        emit DemocracyOn(); //Emitting the event
    }

    /// @notice  Submit a new law proposition
    /// @param _law The proposed logic smart contract address to be added to the VC law pool
    /// @param _duration The time (in second) during which this law should be submitted to voting
    /// @param _revokeLaw Set to true if the law is to be removed instead of added to the pool
    /// @param _stateOfEmergency Set to true if democracy is to be revoked in the senate. Override _law and _revokeLaw.
    /// @return The index of the new law in the law index
    function submitNewLaw(address _law, uint256 _duration, bool _revokeLaw, bool _stateOfEmergency) external restrictedToLawmaker() returns (uint256) {
        lawPropositions.push(address(new LawProposition(_law, _duration, _revokeLaw, _stateOfEmergency)));
        emit NewLawProposal(lawPropositions.length - 1, _law, now + _duration, _revokeLaw, _stateOfEmergency);
        totalLaws = lawPropositions.length;
        return totalLaws;
    }

    /// @notice Vote on a law if you are a legitimate cryptograph owner
    /// @dev For now, only the first # of each edition has voting rights
    /// @param _vote True for agreeing with the law, false for refusing it
    /// @param _lawIndex The LawProposition index to be voted on
    /// @param _cryptographIssue The issue # of the Cryptograph
    /// @param _editionSerial The edition serial # of the Cryptograph.
    function VoteOnLaw(bool _vote, uint256 _lawIndex, uint256 _cryptographIssue, uint256 _editionSerial) external{

        require((_editionSerial == 1 || _editionSerial == 0 ), "Only the first serial of each edition is allowed to vote");

        //Grabbing the cryptograph
        address _cry = CryptographIndexLogicV1(cryptographIndex).getCryptograph(_cryptographIssue, true, _editionSerial);

        //Checking that you are indeed the cryptograph owner
        require(
            TheCryptographLogicV1(address(uint160(_cry))).owner() == msg.sender,
            "You are not an owner allowed to vote"
        );

        //Voting
        LawProposition(lawPropositions[_lawIndex]).vote(_vote, _cry);

        //Emitting the event
        emit Voted(_vote, _lawIndex, _cryptographIssue, _editionSerial);
    }

    /// @notice Enact a law
    /// @dev Will only work if past enaction time and positive votes >= negative votes
    /// @param _lawIndex The index of the LawProposition to be enacted
    function EnactLaw(uint256 _lawIndex) external restrictedToLawmaker(){
        //Grabbing the LawProposition
        LawProposition _lawProp = LawProposition(lawPropositions[_lawIndex]);
        _lawProp.enactable(); //Checks are made internally by the LawPropostion

        //int lawIndex, address law, uint256 enactionTime, bool revokeLaw, bool stateOfEmergency
        emit EnactProposal(_lawIndex, _lawProp.law(), _lawProp.enactionTime(), _lawProp.revokeLaw(), _lawProp.stateOfEmergency());

        if(_lawProp.stateOfEmergency()){ //Dying with thunderous applause
            democracy = false; //BETTER DEAD THAN RED
            emit DemocracyOff(); // I am the senate
        } else {
            if(_lawProp.revokeLaw()){ //Are we deleting a law ?
                laws[_lawProp.law()] = false;
                emit RemovedLogicCodeToVC(_lawProp.law()); //emit the event
            } else { //We are adding a law
                laws[_lawProp.law()] = true;
                emit AddedLogicCodeToVC(_lawProp.law()); //emit the event
            }
        }
    }

}


/// @author Guillaume Gonnaud
/// @title Auction House Logic Code
/// @notice Laws proposition instanced by the senate.
contract LawProposition {

    address public senate; //The address of the senate
    mapping (address => bool) public tokenWhoVoted; //A mapping storing every token that has voted on this law
    address public law; //The address of a smart contract logic code to be potentially used in the VC
    uint256 public enactionTime; //A timestamp storing the earliest time at which the lawmaker can enact the law
    bool public revokeLaw; //A bool true if the proposed smart contract address should be removed instead of added to the VC address pool
    bool public stateOfEmergency; //A boolean indicating whether or not democracy shall be revoked in the senate once this law passes
    uint256 public yesCount; //Number of tokens who voted yes
    uint256 public noCount; //Number of tokens who voted no

    modifier restrictedToSenate(){
        require((msg.sender == senate), "Only callable by senate/Can't vote anymore");
        _;
    }

    /// @notice Law constructor
    /// @dev This contract is meant to be used by the senate only
    /// @param _law The proposed logic smart contract address to be added to the VC law pool
    /// @param _duration The time (in second) during which this law should be submitted to voting
    /// @param _revokeLaw Set to true if the law is to be removed instead of added to the pool
    /// @param _stateOfEmergency Set to true if democracy is to be revoked in the senate. Override _law and _revokeLaw.
    constructor(address _law, uint256 _duration, bool _revokeLaw, bool _stateOfEmergency) public
    {
        //Duration of vote must be at least 24 hours
        require (_duration >= 60*60*24, "Voting should last at least 24 hours");
        require (_duration <= 60*60*24*366, "Voting should last maximum a year");

        //Setting the senate
        senate = msg.sender;

        //Setting the other params
        law = _law;
        revokeLaw = _revokeLaw;
        stateOfEmergency = _stateOfEmergency;
        enactionTime = now + _duration;

    }

    /// @notice Vote on a law
    /// @dev It is the senate responsability to ensure no imposters are voting
    /// @param _vote True if agreed with the law, false is against
    /// @param _token The address of the voting token
    function vote(bool _vote, address _token)  external restrictedToSenate(){

        //Checking if already voted
        require(!tokenWhoVoted[_token], "This token already cast a vote");

        //Setting up the vote
        tokenWhoVoted[_token] = true;

        //Counting the vote
        if(_vote){
            yesCount++;
        } else {
            noCount++;
        }

    }

    /// @notice Check if a law can be enacted. If yes, then prevents further voting.
    /// @dev Throw if not enactable (save gas)
    function enactable()  external restrictedToSenate(){
        require(enactionTime < now, "It is too early to enact the law");
        require(noCount <= yesCount, "Too many voters oppose the law");
        senate = address(0x0); //Disable voting/enacting laws
    }


}
