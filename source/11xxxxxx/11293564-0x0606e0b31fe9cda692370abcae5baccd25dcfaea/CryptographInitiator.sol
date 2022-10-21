// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

/// @author Guillaume Gonnaud
/// @title Cryptograph Initiator
/// @notice Basically a solidity bean so that we can pass it as argument without hitting stack too deep errors when creating a cryptograph
contract CryptographInitiator{
    address public owner; // The desired owner of the Cryptograph
    string public name; // The desired name of the Cryptograph
    string public creator; // The desired creatpr of the Cryptograph
    uint256 public auctionStartTime; //The desired unix (seconds) timestamp at which the initial auction should start
    uint256 public auctionSecondsDuration; // The duration in seconds of the initial auction
    address public publisher; // The address of the publisher. Can edit media url and hash for a cryptograph.
    uint256 public publisherCut; // How much out of 100k parts of profits should the publisher get. e.g. publisherCut = 25000 means 1/4
    address public charity; // The address of the charity
    uint256 public charityCut; // The charity cut out of 100k
    address public thirdParty; // The address of a third party
    uint256 public thirdPartyCut; // The third party cut out of 100k
    uint256 public perpetualAltruismCut; // Will always be set to 25k except very special occasions.
    uint256 public maxSupply; // How many of these cryptographs should be minted maximum
    uint256 public startingPrice; // The Starting price of the auction
    uint256 public cryptographIssue; // The desired issue of the cryptograph (only for editions)
    string public mediaHash; // The desired media hash of the cryptograph
    string public mediaUrl; // The desired media url of the cryptograph

    /// @param _name The desired name of the Cryptograph
    /// @param _auctionStartTime The desired unix (seconds) timestamp at which the initial auction should start
    /// @param _auctionSecondsDuration The duration in seconds of the initial auction
    /// @param _publisher The address of the publisher. Can edit media url and hash for a cryptograph.
    /// @param _publisherCut How much out of 100k parts of profits should the publisher get. e.g. _publisherCut = 25000 mean 1/4 of all profits
    /// @param _charity The address of the charity
    /// @param _charityCut The charity cut out of 100k
    /// @param _thirdParty The address of a third party
    /// @param _thirdPartyCut The third party cut out of 100k
    /// @param _perpetualAltruismCut Will always be set to 25k except very special occasions.
    /// @param _maxSupply How many of these cryptographs should be minted maximum
    /// @param _startingPrice The Starting price of the auction
    /// @param _cryptographIssue The desired issue of the cryptograph (only for editions)
    constructor (
                string memory _name,
                uint256 _auctionStartTime,
                uint256 _auctionSecondsDuration,
                address _publisher,
                uint256 _publisherCut,
                address _charity,
                uint256 _charityCut,
                address _thirdParty,
                uint256 _thirdPartyCut,
                uint256 _perpetualAltruismCut,
                uint256 _maxSupply,
                uint256 _startingPrice,
                uint256 _cryptographIssue
    ) public{
        owner = msg.sender;
        name = _name;
        auctionStartTime = _auctionStartTime;
        auctionSecondsDuration = _auctionSecondsDuration;
        publisher = _publisher;
        publisherCut = _publisherCut;
        charity = _charity;
        charityCut = _charityCut;
        thirdParty = _thirdParty;
        thirdPartyCut = _thirdPartyCut;
        perpetualAltruismCut = _perpetualAltruismCut;
        maxSupply = _maxSupply;
        startingPrice = _startingPrice;
        cryptographIssue = _cryptographIssue;

    }

    modifier restrictedToOwner(){
        require((msg.sender == owner), "Only the creator of this Contract can modify its memory");
        _;
    }

    function setName(string calldata _name) external restrictedToOwner(){
        name = _name;
    }

    function setAuctionStartTime(uint256 _auctionStartTime) external restrictedToOwner(){
        auctionStartTime = _auctionStartTime;
    }

    function setAuctionSecondsDuration(uint256 _auctionSecondsDuration) external restrictedToOwner(){
        auctionSecondsDuration = _auctionSecondsDuration;
    }

    function setPublisher(address _publisher) external restrictedToOwner(){
        publisher = _publisher;
    }

    function setPublisherCut(uint256 _publisherCut) external restrictedToOwner(){
        publisherCut = _publisherCut;
    }

    function setCharity(address _charity) external restrictedToOwner(){
        charity = _charity;
    }

    function setCharityCut(uint256 _charityCut) external restrictedToOwner(){
        charityCut = _charityCut;
    }

    function setThirdParty(address _thirdParty) external restrictedToOwner(){
        thirdParty = _thirdParty;
    }

    function setThirdPartyCut(uint256 _thirdPartyCut) external restrictedToOwner(){
        thirdPartyCut = _thirdPartyCut;
    }

    function setPerpetualAltruismCut(uint256 _perpetualAltruismCut) external restrictedToOwner(){
        perpetualAltruismCut = _perpetualAltruismCut;
    }

    function setMaxSupply(uint256 _maxSupply) external restrictedToOwner(){
        maxSupply = _maxSupply;
    }

    function setStartingPrice(uint256 _startingPrice) external restrictedToOwner(){
        startingPrice = _startingPrice;
    }

    function setCryptographIssue(uint256 _cryptographIssue) external restrictedToOwner(){
        cryptographIssue = _cryptographIssue;
    }

    function setMediaHash(string calldata _mediahash) external restrictedToOwner(){
        mediaHash = _mediahash;
    }

    function setMediaUrl(string calldata _mediaUrl) external restrictedToOwner(){
        mediaUrl = _mediaUrl;
    }

    function setCreator(string calldata _creator) external restrictedToOwner(){
        creator = _creator;
    }

}
