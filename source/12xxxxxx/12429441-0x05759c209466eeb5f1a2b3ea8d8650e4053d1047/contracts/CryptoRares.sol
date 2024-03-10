// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721WithOverrides.sol";

contract CryptoRares is ERC721WithOverrides {
    
    using SafeMath for uint;
    
    uint public constant MAX_RARES = 7777;
    uint public pricePerRareMint = 0.035 ether;
    uint private timeOfLastSale;
    uint private v2Factory;
    uint maxFreeMints = 50;
    uint public raresMinted; 
    bool public dropStarted = false;
    bool constructorMintCalled = false;

    address public cryptoPunksAddress;
    uint public numFreeMintsClaimed;
    mapping (uint => bool) public punkIdToClaimedFreeMint;

    mapping (uint => TYPE) public tokenIdToType;
    mapping (TYPE => string) rareTypeToCryptoRareURI;
    mapping (uint => TYPE) crackerTokenIdToPartyHatType;    
    
    enum TYPE { 
        BLUE_MARIONETTE,
        BLUE_MASK, 
        BOBBLE_HAT, 
        BOBBLE_SCARF,         
        BUNNY_EARS, 
        CHICKEN_BODY, 
        CHICKEN_BOOTS,
        CHICKEN_HEAD,        
        CHICKEN_LEGS,        
        CRACKER,        
        DISK_OF_RETURNING,        
        EASTER_EGG,        
        EASTER_RING,        
        GREEN_MARIONETTE,        
        GREEN_MASK,        
        HALF_FULL_WINE_JUG,
        JACK_LANTERN_MASK,        
        JESTER_HAT,        
        JESTER_SCARF,        
        PUMPKIN,        
        RED_MARIONETTE,
        RED_MASK,
        RUBBER_CHICKEN,
        SANTA_HAT,
        SCYTHE,
        SKELETON_BODY,
        SELETON_BOOTS,
        SELETON_HEAD,
        SKELETON_LEGS,
        TRI_JESTER_HAT,
        TRI_JESTER_SCARF,
        WOOLLY_HAT,
        WOOLLY_SCARF,
        BLUE_PARTYHAT,
        GREEN_PARTYHAT,
        PURPLE_PARTYHAT,
        RED_PARTYHAT,
        WHITE_PARTYHAT,
        YELLOW_PARTYHAT        
    }

    constructor() ERC721("CryptoRares", "RARES") {
        timeOfLastSale = block.timestamp;
     }

    /**
        Mints ares given an array of tokenURIs and rareTypes
     */
    function mintRares(uint _numRares) public payable {
        require(dropStarted == true, "Drop has not started");
        require(raresMinted < MAX_RARES, "The rares minting has ended");
        require(_numRares > 0 && _numRares <= 20, "You can mint minimum 1, maximum 20 rares");
        require(raresMinted.add(_numRares) <= MAX_RARES, "Max amount of rares reached.");
        require(msg.value >= _numRares.mul(pricePerRareMint), "Not enough ether sent");

        // mint
        for (uint i = 0; i < _numRares; i++) {
            uint mintIndex = raresMinted;
            mintRare(mintIndex);
        }
    }

    function claimFreeMint(uint _punkId) external {
        CryptoPunksMarket cryptoPunksMarket = CryptoPunksMarket(cryptoPunksAddress);
        require(cryptoPunksMarket.punkIndexToAddress(_punkId) == msg.sender, "msg.sender is not owner of punk id passed");
        require(dropStarted == true, "Drop has not started");
        require(numFreeMintsClaimed < maxFreeMints, "All free mints have been claimed");
        require(raresMinted < MAX_RARES, "The rares minting has ended");
        require(punkIdToClaimedFreeMint[_punkId] == false, "Punk owner already claimed mint");
        numFreeMintsClaimed = numFreeMintsClaimed.add(1);
        punkIdToClaimedFreeMint[_punkId] = true;
        uint mintIndex = raresMinted;
        mintRare(mintIndex);
    }

    function mintRare(uint _mintIndex) private {

        // randomly get a rareType
        TYPE randType = randomType();

        // use random Type to get the tokenURI
        string memory tokenURI = rareTypeToCryptoRareURI[TYPE(randType)];
        
        // if type is cracker, select party hat for when opened
        if (randType == TYPE.CRACKER) {
            crackerTokenIdToPartyHatType[_mintIndex] = randomPartyHatType();
        }
        _safeMint(msg.sender, _mintIndex);
        _setTokenURI(_mintIndex, tokenURI);
        tokenIdToType[_mintIndex] = TYPE(randType);
        raresMinted = raresMinted.add(1);
        timeOfLastSale = block.timestamp;
    }

    // called from constructorMint only once.
    function mintRareWithType(address _address, TYPE _type) private {

        uint mintIndex = raresMinted;
        string memory tokenURI = rareTypeToCryptoRareURI[TYPE(_type)];
        
        // if type is cracker, select party hat for when opened
        if (_type == TYPE.CRACKER) {
            // generate random party hat URI
            crackerTokenIdToPartyHatType[mintIndex] = randomPartyHatType();
        }
        _safeMint(_address, mintIndex);
        _setTokenURI(mintIndex, tokenURI);
        tokenIdToType[mintIndex] = TYPE(_type);
        raresMinted = raresMinted.add(1);
    }

    /**
        Open cracker rare (the only way to mint a party hat token).
    */ 
    function openCracker(uint _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender,"Owner is not sender");
        require(tokenIdToType[_tokenId] == TYPE.CRACKER, "Token is not a cracker");

        TYPE partyhatOfCracker = crackerTokenIdToPartyHatType[_tokenId];
        string memory uri = rareTypeToCryptoRareURI[partyhatOfCracker];

        _burn(_tokenId); 
        _safeMint(msg.sender, _tokenId);        
        _setTokenURI(_tokenId, uri);
        tokenIdToType[_tokenId] = partyhatOfCracker;
    }

    /**
        Generate random type
     */
    function randomType() private view returns(TYPE) {
        uint16[33] memory rareProbabilities = [391, 147, 288, 347, 74, 407, 400, 392, 424, 48, 230, 273, 508, 294, 119, 210, 343, 319, 282, 415, 294, 167, 203, 92, 155, 391, 518, 562, 490, 308, 306, 316, 288];
        uint rand = randomWithinRange(10000);
        for (uint i = 0; i < 33; i++) {
            if (rand < rareProbabilities[i]) {
                return TYPE(i);
            }
            rand = rand - rareProbabilities[i];
        }
    }

    /**
        Select random party hat URI
     */
    function randomPartyHatType() private view returns(TYPE) {      
        uint8[6] memory probabilities = [10,18,18,18,18,18];
        uint rand = randomWithinRange(100);
        for (uint i = 0; i < 6; i++) {
            if (rand < probabilities[i]) {
                return TYPE(i + 33);
            }
            rand = rand - probabilities[i];
        }     
    }

    function randomWithinRange(uint _max) private view returns (uint) {
        uint random = uint(keccak256(abi.encodePacked(block.timestamp.sub(timeOfLastSale), block.difficulty, v2Factory, raresMinted)));
        return random.mod(_max);
    }
    
    /**
        Get rares owned by address.
     */
    function tokensOfOwner(address _owner) public view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    receive() payable external { }

    /////////////////////////////////
    ///// Only owner functions /////
    /////////////////////////////////

    /**
        Not called in constructor because `addURIToType` needs to be called first for all types.
        `addURIToType` is to be called post-deployment.
     */
    function constructorMint() external onlyOwner {
        
        require(constructorMintCalled == false, "Already minted once!");        
        
        // infernalToast
        mintRareWithType(address(0x7132C9f36abE62EAb74CdfDd08C154c9AE45691B), TYPE.SANTA_HAT); 
        // dulab
        mintRareWithType(address(0x7CbD34f7F522962c20564792F81DDff0aBE393D4), TYPE.SANTA_HAT); 
        // commute
        mintRareWithType(address(0x2bd8C23d6f947CD2a22F7AB3305920FF71957C45), TYPE.RED_MASK); 
        // santonio
        mintRareWithType(address(0xeD2614507065581B11831bb8661555402feB0722), TYPE.CRACKER);
        // fap_pablo giveaway
        mintRareWithType(address(0x19dd3213473863c4f2e38ad093D8C346f6F991c5), TYPE.SANTA_HAT);
        // owner
        mintRareWithType(address(0x1A6B15ff611B75eFaA5F91cf0A9b9b396D2BF73C), TYPE.SANTA_HAT);
        mintRareWithType(address(0x1A6B15ff611B75eFaA5F91cf0A9b9b396D2BF73C), TYPE.CRACKER);
        mintRareWithType(address(0x1A6B15ff611B75eFaA5F91cf0A9b9b396D2BF73C), TYPE.BUNNY_EARS);
        mintRareWithType(address(0x1A6B15ff611B75eFaA5F91cf0A9b9b396D2BF73C), TYPE.GREEN_MASK);
        mintRareWithType(address(0x1A6B15ff611B75eFaA5F91cf0A9b9b396D2BF73C), TYPE.RED_MASK);
        mintRareWithType(address(0x1A6B15ff611B75eFaA5F91cf0A9b9b396D2BF73C), TYPE.BLUE_MASK);
        
        // lock function
        constructorMintCalled = true;
    }

    function addURIToType(uint _type, string memory _uri) external onlyOwner {
        rareTypeToCryptoRareURI[TYPE(_type)] = _uri;
    }
    
    function setv2Factory(uint _i) external onlyOwner {
        v2Factory = _i;
    }

    function setCryptoPunksMarketAddress(address _address) external onlyOwner {
        cryptoPunksAddress = _address;
    }

    function setDropStarted(bool _start) external onlyOwner {
        dropStarted = _start;
    }
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}

contract CryptoPunksMarket {
    mapping (uint => address) public punkIndexToAddress;
}
