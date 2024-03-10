// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721WithOverrides.sol";
import "./CryptoRares.sol";
import "./RunePunks.sol";

contract RarePunks is ERC721WithOverrides {

    address payable public cryptoRaresAddress; // to check for ownership of CryptoRares
    address payable public runePunkAddress; // to check for ownership of CryptoRares
    address cryptoPunksAddress; // to check for ownership of CryptoPunks   
    mapping (uint => bool) public validTypes;

    // trackers for minting -> decoupling -> reminting
    mapping (uint => uint) public rarePunkIdToCryptoPunkId; 
    mapping (uint => bool) public cryptoPunkIdToIsMinted; // to disable double-mints on cryptopunks
    mapping (uint => uint) public rarePunkIdToRunePunkId;
    mapping (uint => bool) public rarePunkIdToIsRunePunk;

    
    constructor() ERC721("RarePunks", "RAREPUNK") {
        // valid types at launch
        validTypes[1] = true;
        validTypes[2] = true;
        validTypes[4] = true;
        validTypes[14] = true;
        validTypes[17] = true;
        validTypes[21] = true;
        validTypes[23] = true;
        validTypes[29] = true;
        validTypes[31] = true;
        validTypes[33] = true;
        validTypes[34] = true;
        validTypes[35] = true;
        validTypes[36] = true;
        validTypes[37] = true;
        validTypes[38] = true;
     }
    
    function mintRarePunkWithCryptoPunk(uint _cryptoRareTokenId, string memory _rarePunkTokenURI, uint _cryptoPunkTokenId) public {
        
        CryptoRares cryptoRares = CryptoRares(cryptoRaresAddress);
        CryptoPunksMarket cryptoPunksMarket = CryptoPunksMarket(cryptoPunksAddress);
        
        require(cryptoPunkIdToIsMinted[_cryptoPunkTokenId] == false, "RarePunk was already minted with CryptoPunk");
        require(validTypes[uint(cryptoRares.tokenIdToType(_cryptoRareTokenId))],"CryptoRare is not a valid wearable");
        require(cryptoRares.ownerOf(_cryptoRareTokenId) == msg.sender, "msg.sender is not owner of rare token");        
        require(cryptoPunksMarket.punkIndexToAddress(_cryptoPunkTokenId) == msg.sender, "msg.sender is not owner of punk id passed");
        
        cryptoRares.transferFrom(msg.sender, address(this), _cryptoRareTokenId);
        _safeMint(msg.sender, _cryptoRareTokenId);
        _setTokenURI(_cryptoRareTokenId, _rarePunkTokenURI);
        
        rarePunkIdToIsRunePunk[_cryptoRareTokenId] = false;
        rarePunkIdToCryptoPunkId[_cryptoRareTokenId] = _cryptoPunkTokenId;
        cryptoPunkIdToIsMinted[_cryptoPunkTokenId] = true;
    }


    function mintRarePunkWithRunePunk(uint _cryptoRareTokenId, string memory _rarePunkTokenURI, uint _runePunkTokenId) public {
        CryptoRares cryptoRares = CryptoRares(cryptoRaresAddress);
        RunePunks runePunks = RunePunks(runePunkAddress);

        require(validTypes[uint(cryptoRares.tokenIdToType(_cryptoRareTokenId))],"CryptoRare is not a valid wearable");        
        require(cryptoRares.ownerOf(_cryptoRareTokenId) == msg.sender, "msg.sender is not owner of rare token");        
        require(runePunks.ownerOf(_runePunkTokenId) == msg.sender, "msg.sender is not owner of runepunk id passed");

        cryptoRares.transferFrom(msg.sender, address(this), _cryptoRareTokenId);
        runePunks.transferFrom(msg.sender, address(this), _runePunkTokenId);
        rarePunkIdToRunePunkId[_cryptoRareTokenId] = _runePunkTokenId;
        
        _safeMint(msg.sender, _cryptoRareTokenId);
        _setTokenURI(_cryptoRareTokenId, _rarePunkTokenURI);
        rarePunkIdToIsRunePunk[_cryptoRareTokenId] = true;
    }

    function decoupleRarePunkFromRunePunk(uint _rarePunkTokenId) external {
        
        require(rarePunkIdToIsRunePunk[_rarePunkTokenId] == true, "RarePunk was not minted from runepunk");
        require(msg.sender == ownerOf(_rarePunkTokenId), "Msg.sender is not owner of rarepunk");
        
        _burn(_rarePunkTokenId);
        
        CryptoRares cryptoRares = CryptoRares(cryptoRaresAddress);
        cryptoRares.transferFrom(address(this), msg.sender, _rarePunkTokenId);
        
        RunePunks runePunks = RunePunks(runePunkAddress);
        runePunks.transferFrom(address(this), msg.sender, rarePunkIdToRunePunkId[_rarePunkTokenId]);
    }

    function decoupleRarePunkFromCryptoPunk(uint _rarePunkTokenId) external {
       
        require(rarePunkIdToIsRunePunk[_rarePunkTokenId] == false, "RarePunk was not minted from CryptoPunk");
        require(msg.sender == ownerOf(_rarePunkTokenId), "Msg.sender is not owner of rarepunk");
       
        _burn(_rarePunkTokenId);
        CryptoRares cryptoRares = CryptoRares(cryptoRaresAddress);
        cryptoRares.transferFrom(address(this), msg.sender, _rarePunkTokenId);

        uint cryptoPunkId = rarePunkIdToCryptoPunkId[_rarePunkTokenId];
        cryptoPunkIdToIsMinted[cryptoPunkId] = false;
        rarePunkIdToCryptoPunkId[_rarePunkTokenId] = 0;
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
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

    function setCryptoRaresAddress(address payable _address) external onlyOwner {
        cryptoRaresAddress = _address;
    }

    function setRunePunksAddress(address payable _address) external onlyOwner {
        runePunkAddress = _address;
    }

    function setCryptoPunkMarketAddress(address _address) external onlyOwner {
        cryptoPunksAddress = _address;
    }

    function addValidType(uint _type) external onlyOwner {
        validTypes[_type] = true;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
