// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./CryptographFactoryV1.sol";
import "./TheCryptographProxiedV1.sol";
import "./TheCryptographLogicV1.sol";
import "./SingleAuctionProxiedV1.sol";
import "./SingleAuctionLogicV1.sol";
import "./CryptographIndexLogicV1.sol";
import "./AuctionHouseLogicV1.sol";
import "./MintingAuctionLogicV1.sol";
import "./MintingAuctionProxiedV1.sol";
import "./CryptographInitiator.sol";

/// @author Guillaume Gonnaud 2019
/// @title Cryptograph Factory Logic Code
/// @notice The main contract used by publisher to release and edit cryptographs. Cast this smart contract on the proxy address for interaction.
contract CryptographFactoryLogicV1 is VCProxyData, CryptographFactoryHeaderV1, CryptographFactoryStoragePublicV1 {

    constructor() public
    {
        //Self intialize (nothing)
    }

    /// @notice Init function of the Cryptograph Factory
    /// @dev Callable only once after deployment
    /// @param _officialPublisher The address that perpetual altruism will be using consistently through all deployments
    /// @param _targetVC The address of the proxied Version Control
    /// @param _targetAuctionHouse The address of the proxied Auction House
    /// @param _targetIndex The address of the proxied Index
    /// @param _targetCryLogicVersion The code index of TheCryptographLogicV1 in the version control
    /// @param _targetAuctionLogicVersion  The code index of SingleAuctionLogicV1 in the version control
    /// @param _targetAuctionBidLogicVersion  The code index of SingleAuctionBidLogicV1 in the version control
    /// @param _targetMintingAuctionLogicVersion  The code index of MintingAuctionLogicV1 in the version control
    function init(
        address _officialPublisher,
        address _targetVC,
        address _targetAuctionHouse,
        address _targetIndex,
        uint256 _targetCryLogicVersion,
        uint256 _targetAuctionLogicVersion,
        uint256 _targetAuctionBidLogicVersion,
        uint256 _targetMintingAuctionLogicVersion
    ) external {

        require(!initialized, "The Cryptograph Factory has already been initialized");
        initialized = true;
        officialPublisher = _officialPublisher;
        targetVC = _targetVC;
        targetAuctionHouse = _targetAuctionHouse;
        targetIndex = _targetIndex;
        targetCryLogicVersion = _targetCryLogicVersion;
        targetAuctionLogicVersion = _targetAuctionLogicVersion;
        targetAuctionBidLogicVersion = _targetAuctionBidLogicVersion;
        targetMintingAuctionLogicVersion = _targetMintingAuctionLogicVersion;
        communityMintable = false;
    }

    /// @notice Create a Cryptograph
    /// @dev emit CryptographCreated event. Official cryptographs need their auction locked-in afterwards.
    /// @param _cryInitiator The cryptograph Initiator object
    /// @return The issue number of the newly created Cryptograph
    function createCryptograph (address _cryInitiator) external returns (uint256){

        bool offi = msg.sender == officialPublisher;

        require(communityMintable || offi, "Community Cryptographs can't be created at the moment");

        //Instance the Cryptograph
        address newCryptographProxied;
        address newSingleAuctionProxiedV1;
        (newCryptographProxied, newSingleAuctionProxiedV1) = instanceCryptograph(_cryInitiator, offi);

        //Book the Cryptograph into the index and get the issue #, then init
        uint256 _issue;
        if(offi){
            //Inserting an official Cryptograph
            _issue = CryptographIndexLogicV1(targetIndex).insertACryptograph(newCryptographProxied);
        } else {
             //Inserting a community Cryptograph
            _issue = CryptographIndexLogicV1(targetIndex).insertACommunityCryptograph(newCryptographProxied);
        }

        TheCryptographLogicV1(newCryptographProxied).initCry(
                _issue, 0, offi, newSingleAuctionProxiedV1, _cryInitiator, address(0)
            );

        //Setting hash and url
        TheCryptographLogicV1(newCryptographProxied).setMediaHash(
            CryptographInitiator(_cryInitiator).mediaHash()
        );
        TheCryptographLogicV1(newCryptographProxied).setMediaUrl(
            CryptographInitiator(_cryInitiator).mediaUrl()
        );

        emit CryptographCreated(_issue, newCryptographProxied, offi);
        return _issue;
    }

    /// @notice Create an edition
    /// @dev emit CryptographEditionAdded event
    /// @param _editionSize How many cryptographs can be minted in this edition
    /// @return The Cryptograph issue # of the newly created Cryptograph Edition
    function createEdition(uint256 _editionSize) external returns (uint256){

        uint256 _issue;

        bool offi = msg.sender == officialPublisher;

        require(communityMintable || offi, "community Cryptographs can't be created at the moment");

        //Book the edition into the index and get the issue #
        if(offi){
            //Inserting an official Cryptograph
            _issue = CryptographIndexLogicV1(targetIndex).createAnEdition(msg.sender, _editionSize);
        } else {
            //Inserting a community Cryptograph
            _issue = CryptographIndexLogicV1(targetIndex).createACommunityEdition(msg.sender, _editionSize);
        }
        emit CryptographEditionAdded(_issue, _editionSize, offi);
        return _issue;
    }

    /// @notice Mint a Cryptograph that is part of an edition.
    /// @dev emit CryptographEditionMinted event. Only callable by the original edition creator. Official cryptographs need their auction locked-in afterwards.
    /// @param _cryInitiator The cryptograph Initiator for the edition
    /// @return The serial number of the newly created Cryptograph edition member
    function mintEdition (address _cryInitiator) external returns (uint256){

        bool offi = msg.sender == officialPublisher;

        uint256 _issue = CryptographInitiator(_cryInitiator).cryptographIssue();

        //Check that we are properly minting an Edition and not a GGBMA/Unique cryptograph
        require(
            CryptographIndexLogicV1(targetIndex).getCryptograph(_issue, offi, 0) == address(0x0),
            "Can't manually mint a GGBMA");

        //Instance the Cryptograph
        address newCryptographProxied;
        address newSingleAuctionProxiedV1;
        (newCryptographProxied, newSingleAuctionProxiedV1) = instanceCryptograph(_cryInitiator, offi);

        //Book the Cryptograph into the index and get the serial #
        uint256 _editionSerial;
        _editionSerial = CryptographIndexLogicV1(targetIndex).mintAnEdition(
            msg.sender,
            _issue,
            offi,
            address(newCryptographProxied)
        );

        //Init the Cryptograph
        TheCryptographLogicV1(address(newCryptographProxied)).initCry(
            _issue, _editionSerial, offi, address(newSingleAuctionProxiedV1), _cryInitiator, address(0)
        );
        emit CryptographEditionMinted(
            _issue,
            _editionSerial,
            newCryptographProxied,
            offi
        );

        //Setting hash and url
        TheCryptographLogicV1(newCryptographProxied).setMediaHash(
            CryptographInitiator(_cryInitiator).mediaHash()
        );
        TheCryptographLogicV1(newCryptographProxied).setMediaUrl(
            CryptographInitiator(_cryInitiator).mediaUrl()
        );

        return _editionSerial;
    }


    /// @notice ReInitialize an already created Cryptograph
    /// @dev This permit to release nameless cryptograph at a specific serial #, only to name them properly later (up until the auction start)
    /// If auction started but is not locked, use reinitAuction.
    /// @param _CryptographToEdit The address of the cryptograph you want to re-init
    /// @param _cryInitiator The Cryptograph initator with the name to be changed
    function reInitCryptograph(address _CryptographToEdit, address _cryInitiator)  external {
        require(msg.sender == officialPublisher, "Only official Cryptographs can be edited after serial # reservation");
        TheCryptographLogicV1(_CryptographToEdit).initCry(
            TheCryptographLogicV1(_CryptographToEdit).issue(),
            TheCryptographLogicV1(_CryptographToEdit).serial(),
            true,
            TheCryptographLogicV1(_CryptographToEdit).myAuction(),
            _cryInitiator,
            address(0)
        );
    }


    /// @notice ReInitialize an already created Auction. Not possible after locking.
    /// @dev Auction re-initializable until locked. No bid accepted if unlocked.
    /// @param _auctionToEdit The address of the auction you want to edit
    /// @param _cryInitiator The desired unix (seconds) timestamp at which the initial auction should start
    /// @param _lock Shall further re-initilization be allowed ?
    function reInitAuction(
        address _auctionToEdit,
        address _cryInitiator,
        bool _lock
    ) external {
        require(msg.sender == officialPublisher, "Only PA can reinit auctions");

        //Call init
        SingleAuctionLogicV1(_auctionToEdit).initAuction(
            SingleAuctionLogicV1(_auctionToEdit).myCryptograph(),
            _cryInitiator,
            _lock
        );
    }

    /// @notice Lock an auction to prevent anyone from re-editing it and allow bidding
    /// @dev When releasing ready-to launch cryptographs, you should lock ASAP
    /// @param _cryptographIssue The issue # of the Cryptograph auction you want to lock
    /// @param _editionSerial If locking auction on an edition, specify it's specific edition serial # here
    function lockAuction(uint256 _cryptographIssue, uint256 _editionSerial) external {
        require(msg.sender == officialPublisher, "Only Perpetual Altruism can lock an auction");
        SingleAuctionLogicV1(
            TheCryptographLogicV1(
                CryptographIndexLogicV1(targetIndex).getCryptograph(
                    _cryptographIssue, true, _editionSerial)
            ).myAuction()
        ).lock();
    }

    /// @notice Set the media hash for a cryptograph
    /// @dev emit the MediaHash event in the cryptograph instance for  web3 retrieval. It's best practice to call this function soon after cryptograph creation
    /// @param _cryptographIssue The issue # of the Cryptograph you want to set the media hash for
    /// @param _editionSerial If setting hash on an edition, specify its specific edition serial # here
    function setMediaHash(uint256 _cryptographIssue, uint256 _editionSerial, string calldata _mediaHash) external{
        TheCryptographLogicV1 _cry = TheCryptographLogicV1(CryptographIndexLogicV1(targetIndex).getCryptograph(
                    _cryptographIssue, true, _editionSerial)
            );
        require(msg.sender == SingleAuctionLogicV1(_cry.myAuction()).publisher(),
            "Only the publisher of a Cryptograph can edit its media hash"
        );

        _cry.setMediaHash(_mediaHash);
    }

    /// @notice Set the media url for a cryptograph
    /// @dev emit the MediaUrl event in the cryptograph instance for  web3 retrieval. It's best practice to call this function soon after cryptograph creation
    /// @param _cryptographIssue The issue # of the Cryptograph you want to set the media url for
    /// @param _editionSerial If setting url on an edition, specify its specific edition serial # here
    function setMediaUrl(uint256 _cryptographIssue, uint256 _editionSerial, string calldata _mediaUrl) external{
        TheCryptographLogicV1 _cry = TheCryptographLogicV1(CryptographIndexLogicV1(targetIndex).getCryptograph(
                    _cryptographIssue, true, _editionSerial)
            );
        require(msg.sender == SingleAuctionLogicV1(_cry.myAuction()).publisher(), "Only the publisher of a Cryptograph can edit its media URL");

        _cry.setMediaUrl(_mediaUrl);
    }

    /// @notice Instance a Cryptograph
    /// @dev The SingleAuction is init() but TheCryptograph is not
    /// @param _cryInitiator The Cryptograph Iniator address
    /// @return (new CryptographAddress, new SingleAuctionAddress)
    function instanceCryptograph( address _cryInitiator, bool _official) internal returns (address, address){

        //Instance a new Cryptograph
        TheCryptographProxiedV1 newCryptographProxied = new TheCryptographProxiedV1(targetCryLogicVersion, targetVC);

        //Instance a new auction
        SingleAuctionProxiedV1 newSingleAuctionProxiedV1 = new SingleAuctionProxiedV1(targetAuctionLogicVersion, targetVC, targetAuctionBidLogicVersion);

        //-----------------------
        //Init the auction
        SingleAuctionLogicV1(address(newSingleAuctionProxiedV1)).initAuction(
            address(newCryptographProxied),
            _cryInitiator,
            !_official //Will lock the auction setup if not an official Cryptograph
        );

        //-----------------------

        //Checking any bamboozling with the fees
        if(!_official){
                assert(SingleAuctionLogicV1(address(newSingleAuctionProxiedV1)).perpetualAltruismCut() >= 25000);
            }

        assert(
            SingleAuctionLogicV1(address(newSingleAuctionProxiedV1)).perpetualAltruismCut() +
            SingleAuctionLogicV1(address(newSingleAuctionProxiedV1)).publisherCut() +
            SingleAuctionLogicV1(address(newSingleAuctionProxiedV1)).charityCut() +
            SingleAuctionLogicV1(address(newSingleAuctionProxiedV1)).thirdPartyCut() == 100000
            );

        assert(SingleAuctionLogicV1(address(newSingleAuctionProxiedV1)).startTime() <=
        SingleAuctionLogicV1(address(newSingleAuctionProxiedV1)).endTime());

        return (address(newCryptographProxied), address(newSingleAuctionProxiedV1));

    }

    /*
    ====================================================
                    GENERALIZED GBM STUFF
    ====================================================
    */

    /*
        The processus for holding a Generalized GBM Auction (GGBMA) is as follow :
        -Call "createGGBMA" to create a generalized GBM auction
            -> It will have a cryptograph template that will be copied at minting time
            -> Edition serial is 0 (prototype) for get purposes.
            -> Reminder that once instanced, changes to the prototype don't carry over to copies.
        -"reInitCryptograph", "setMediaHash", "setMediaURL" works on the GGBMA prototype and copies just like a normal cryptograph
        -"reInitAuction", "lockAuction" allows to interact with a GGBMA just like a normal auction.
        -Once the auction is over, bidders calling win() on the auction serial #0 will instead mint a new cryptograph/Single auction pair
            -> This pair is initiated to be past their initial auction already and to have the bidder as the new owner.
    */

    /// @notice Create a Cryptograph
    /// @dev emit CryptographCreated event. Official cryptographs need their auction locked-in afterwards.
    /// @param _cryInitiator The cryptograph initiator for the desired GGBMA
    /// @return The serial number of the newly created Cryptograph
    function createGGBMA (address _cryInitiator) external returns (uint256){

        require(false, "GGBMA creation is disabled for launch, they will need an update approved by the senate");

        uint256 _issue; //The issue # we will get

        bool offi = msg.sender == officialPublisher;

        require(communityMintable || offi, "community Cryptographs can't be created at the moment");

        //Book the edition into the index and get the issue #
        if(offi){
            //Inserting an official Cryptograph
            _issue = CryptographIndexLogicV1(targetIndex).createAGGBMA(msg.sender, CryptographInitiator(_cryInitiator).maxSupply());
        } else {
            //Inserting a community Cryptograph
            _issue = CryptographIndexLogicV1(targetIndex).createACommunityGGBMA(msg.sender, CryptographInitiator(_cryInitiator).maxSupply());
        }
        emit CryptographEditionAdded(_issue, CryptographInitiator(_cryInitiator).maxSupply(), offi);

        //Instance the Cryptograph and the auction
        address newCryptographProxied;
        address newMintingAuctionProxiedV1;
        (newCryptographProxied, newMintingAuctionProxiedV1) = instanceCryptographGGBMA(_cryInitiator, _issue);

        //Book the prototype at index0 of the edition

        CryptographIndexLogicV1(targetIndex).mintAnEditionAt(
            _issue,
            0,
            offi,
            address(newCryptographProxied)
        );

        emit CryptographCreated(_issue, newCryptographProxied, offi);
        mintingAuctionSupply[newMintingAuctionProxiedV1] = CryptographInitiator(_cryInitiator).maxSupply();

        return _issue;
    }

    /// @notice Instance a Cryptograph/Minting Auction pair
    /// @dev The MintingAuction is init() but TheCryptograph is not
    /// @param _cryInitiator The cryptograph Initator the GGBMA will be created after
    /// @return (new CryptographAddress, new MintingAuctionAddress)
    function instanceCryptographGGBMA(address _cryInitiator, uint256 _issue) internal returns (address, address){


        //Is the GGBMA published by PA or a third paty ?
        bool _official; //Set to false by default
        if(msg.sender == officialPublisher){
            _official = true;
        }

        require(communityMintable || _official, "community Cryptographs can't be created at the moment");

        //Instance a new Cryptograph
        address newCryptographProxied = address(new TheCryptographProxiedV1(targetCryLogicVersion, targetVC));

        //Instance a new auction
        address newMintingAuctionProxiedV1 = address(new MintingAuctionProxiedV1(targetMintingAuctionLogicVersion, targetVC));

        //-----------------------

        TheCryptographLogicV1(address(newCryptographProxied)).initCry(
                _issue, 0, _official, newMintingAuctionProxiedV1, _cryInitiator, address(0)
            );

        //Init the auction
        MintingAuctionLogicV1(address(newMintingAuctionProxiedV1)).initAuction(
            newCryptographProxied,
            _cryInitiator,
            !_official //Will lock the auction setup if not an official Cryptograph
        );
        //-----------------------

        //Setting hash and url
        TheCryptographLogicV1(newCryptographProxied).setMediaHash(
            CryptographInitiator(_cryInitiator).mediaHash()
        );
        TheCryptographLogicV1(newCryptographProxied).setMediaUrl(
            CryptographInitiator(_cryInitiator).mediaUrl()
        );

        //Checking any bamboozling with the fees
        if(!_official){
                assert(MintingAuctionLogicV1(address(newMintingAuctionProxiedV1)).perpetualAltruismCut() >= 25000);
            }

        assert(
            MintingAuctionLogicV1(address(newMintingAuctionProxiedV1)).perpetualAltruismCut() +
            MintingAuctionLogicV1(address(newMintingAuctionProxiedV1)).publisherCut() +
            MintingAuctionLogicV1(address(newMintingAuctionProxiedV1)).charityCut() +
            MintingAuctionLogicV1(address(newMintingAuctionProxiedV1)).thirdPartyCut() == 100000
            );

        assert(MintingAuctionLogicV1(address(newMintingAuctionProxiedV1)).startTime() <=
            MintingAuctionLogicV1(address(newMintingAuctionProxiedV1)).endTime());


        return (address(newCryptographProxied), address(newMintingAuctionProxiedV1));
    }

    /// @notice Mint a Cryptograph/SA pair initialized to a GGBMA winner
    /// @dev To be called BEFORE the bid funds are distributed to the publisher
    /// @param _issue The issue number of the GGBMA
    /// @param _isOfficial Is it an official or community GGBMA ?
    /// @param _winner The address of someone eligible to win the auction
    function mintGGBMA(uint256 _issue, bool _isOfficial, address _winner) external returns(bool){
        require(msg.sender == targetAuctionHouse, "Only the auction house can ask the factory to mint new copies for a GGBMA");

        //Grabbing the GGBMA
        address _ggbma = TheCryptographLogicV1(
                CryptographIndexLogicV1(targetIndex).getCryptograph(_issue, _isOfficial, 0)
            ).myAuction();

        //Calculating the claimant ranking
        uint256 positionInAuction; //0

        //Browse the BidLink chain until the link above us has a bid greater or equal to us
        address currentLink = MintingAuctionLogicV1(_ggbma).bidLinks(MintingAuctionLogicV1(_ggbma).highestBidder());
        bool stop = currentLink == address(0x0); //Do not even enter the loop if there is no highest bidder
        while(!stop){
            if(BidLink(currentLink).bidder() == _winner){
                positionInAuction++; //Increasing the count (serial # start at 1 while counter start at 0)
                stop = true;
            } else if(BidLink(currentLink).below() == address(0x0)){ //Checking if we have reached the bottom
                positionInAuction = 0; //We were not a bidder...
                stop = true;
            } else {
                //Going down
                positionInAuction++;
                currentLink = BidLink(currentLink).below();
            }
        }

        require(positionInAuction != 0, "Could not find your bid in this auction");

        //Checking if we can mint. No refunds as those are handled by the auction itself.
        //The way we check for minting available is by checking if there is a standing bid.
        require(MintingAuctionLogicV1(_ggbma).currentBids(_winner) != 0, "You already minted your cryptograph");

        /*
        Double entry attack possible here on third parties minted cryptographs, as initiators are user instanced.

        Limitation of exploit :
        -only "views" are called (so no state-changing gas stealing)
        -only on community GGBMA

        Consequence at worst inside cryptograph ecosystem : The attacker (who is the original creator of the GGBMA)
        can make changes to each newly minted cryptograph (so that they are not all unique).

        => Not a bug. It's a feature.

        */

        //Instance the Cryptograph
        address newCryptographProxied;
        address newSingleAuctionProxiedV1;
        address initiator = MintingAuctionLogicV1(_ggbma).initiator();

        (newCryptographProxied, newSingleAuctionProxiedV1) = instanceCryptograph(initiator, _isOfficial);

        //Book the Cryptograph into the index
        CryptographIndexLogicV1(targetIndex).mintAnEditionAt(
            _issue, // Issue #
            positionInAuction, // Serial #
            _isOfficial,
            address(newCryptographProxied)
        );

        //Init the cryptograph
        TheCryptographLogicV1(newCryptographProxied).initCry(
                _issue, positionInAuction, _isOfficial, newSingleAuctionProxiedV1, initiator, _winner
            );

        //Setting hash and url
        TheCryptographLogicV1(newCryptographProxied).setMediaHash(
            CryptographInitiator(initiator).mediaHash()
        );
        TheCryptographLogicV1(newCryptographProxied).setMediaUrl(
            CryptographInitiator(initiator).mediaUrl()
        );

        //Locking the auction
        SingleAuctionLogicV1(newSingleAuctionProxiedV1).lock();
    }

    /// @notice Set the ability for third parties to create their own cryptographs.
    /// @dev False at creation
    /// @param _communityMintable Are community Cryptographs mintable ?
    function setCommunityMintable(bool _communityMintable) external {

        require(msg.sender == officialPublisher, "Only Perpetual Altruism can set communityMintable");

        communityMintable = _communityMintable;
    }
}

