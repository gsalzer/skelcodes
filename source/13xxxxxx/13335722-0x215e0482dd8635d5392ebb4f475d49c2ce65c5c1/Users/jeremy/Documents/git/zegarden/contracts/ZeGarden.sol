// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//  ███████ ███████  ██████   █████  ██████  ██████  ███████ ███    ██
//     ███  ██      ██       ██   ██ ██   ██ ██   ██ ██      ████   ██
//    ███   █████   ██   ███ ███████ ██████  ██   ██ █████   ██ ██  ██
//   ███    ██      ██    ██ ██   ██ ██   ██ ██   ██ ██      ██  ██ ██
//  ███████ ███████  ██████  ██   ██ ██   ██ ██████  ███████ ██   ████
//  🥯 bagelface
//  🐦 @bagelface_
//  🎮 bagelface#2027
//  📬 bagelface@protonmail.com

contract ZeGarden is ERC721, Ownable, VRFConsumerBase, PaymentSplitter {
  using Address for address;

  uint256 internal LINK_FEE;
  bytes32 internal LINK_KEY_HASH;
  address[] internal _payees;
  uint256 internal _tokenIds;
  uint256 internal _reserved;
  uint256 internal _tokenOffset;
  string internal _baseTokenURI;

  uint256 public PRESALE_MAX_MINT = 3;
  uint256 public PRESALE_MINT_PRICE = 0.042069 ether;
  uint256 public MAX_MINT = 10;
  uint256 public MINT_PRICE = 0.066 ether;
  uint256 public MAX_SUPPLY = 7777;
  uint256 public MAX_RESERVED = 77;
  string public PROVENANCE_HASH; // Keccak-256

  string public contractURI;
  string public flowersURI;
  bool public presaleActive;
  bool public saleActive;
  bool public revealed;
  mapping(address => bool) public whitelist;

  constructor(
    string memory baseTokenURI,
    address vrfCoordinator,
    address linkToken,
    bytes32 keyHash,
    uint256 linkFee,
    address[] memory payees,
    uint256[] memory shares
  )
    ERC721("ZeGarden", "FLOWER")
    PaymentSplitter(payees, shares)
    VRFConsumerBase(vrfCoordinator, linkToken)
  {
    LINK_KEY_HASH = keyHash;
    LINK_FEE = linkFee;
    _baseTokenURI = baseTokenURI;
    _payees = payees;
  }

  function totalSupply() external view returns (uint256) {
    return _tokenIds;
  }

  function tokenOffset() public view returns (uint256) {
    require(_tokenOffset != 0, "Offset has not been generated");

    return _tokenOffset;
  }

  function flowerId(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "Query for nonexistent token");

    return (tokenId + tokenOffset()) % MAX_SUPPLY;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    require(bytes(PROVENANCE_HASH).length == 0, "Provenance hash has already been set");

    PROVENANCE_HASH = provenanceHash;
  }

  function setBaseTokenURI(string memory URI) public onlyOwner {
    _baseTokenURI = URI;
  }

  function setContractURI(string memory URI) public onlyOwner {
    contractURI = URI;
  }

  function setFlowersURI(string memory URI) public onlyOwner {
    flowersURI = URI;
  }

  function flipPresaleActive() public onlyOwner {
    presaleActive = !presaleActive;
  }

  function flipSaleActive() public onlyOwner {
    saleActive = !saleActive;
  }

  function flipRevealed() public onlyOwner {
    require(_tokenOffset != 0, "Offset has not been generated");

    revealed = !revealed;
  }

  function setTokenOffset() public onlyOwner {
    require(_tokenOffset == 0,                  "Offset is already set");
    require(bytes(PROVENANCE_HASH).length != 0, "Provenance hash has not been set");

    requestRandomness(LINK_KEY_HASH, LINK_FEE);
  }

  function setWhitelist(address[] calldata gardeners, bool allow) public onlyOwner {
    for (uint256 i = 0; i < gardeners.length; i++) {
      whitelist[gardeners[i]] = allow;
    }
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    _tokenOffset = randomness % MAX_SUPPLY;
  }

  function reserve(uint256 amount, address to) public onlyOwner {
    require(_reserved + amount < MAX_RESERVED, "Exceeds maximum number of reserved tokens");

    _mintAmount(amount, to);
    _reserved += amount;
  }

  function presaleMint(uint256 amount) public payable {
    require(presaleActive,                                      "Presale is not active");
    require(whitelist[msg.sender],                              "Address not whitelisted");
    require(msg.value == PRESALE_MINT_PRICE * amount,           "Invalid Ether amount sent");
    require(balanceOf(msg.sender) + amount <= PRESALE_MAX_MINT, "Exceeds remaining whitelist balance");

    _mintAmount(amount, msg.sender);
  }

  function mint(uint256 amount) public payable {
    require(saleActive,                       "Sale is not active");
    require(amount <= MAX_MINT,               "Exceeds the maximum amount to mint at once");
    require(msg.value == MINT_PRICE * amount, "Invalid Ether amount sent");

    _mintAmount(amount, msg.sender);
  }

  function _mintAmount(uint256 amount, address to) internal {
    require(_tokenIds + amount < MAX_SUPPLY, "Exceeds maximum number of tokens");

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, _tokenIds);
      _tokenIds += 1;
    }
  }

  function withdrawLINK(address to, uint256 amount) external onlyOwner {
    require(LINK.balanceOf(address(this)) >= amount, "Insufficient LINK balance");
    LINK.transfer(to, amount);
  }

  function withdrawAll() external onlyOwner {
    for (uint256 i = 0; i < _payees.length; i++) {
      release(payable(_payees[i]));
    }
  }
}

/*
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐🍐🍐🍐⚫🍐⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐🍐⚫⚫🌼🌼🌕🌚🍐⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🌳🍐🍐🍐🍐🍐⚪⚪⚪⚪⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪🍐🍐⚫🌼🌼🌼🌕🌼🌼💭🌳⚪⚪⚪⚪⚪🌳🍐🍐🍐🍐🍐⚫🍐⚫🍐⚫⚫🍐⚪⚪⚪⚪⚪⚪
  ⚪⚪⚪⚪⚪🍐🍐🍐🌚⚫🌼🌼🌼🌼🌼🌼🌕⚫🍐⚪🍐🍐🍐⚫⚫⚫🌚🌼⚫⚫🌕🌼🌕🌕🌕⚫🍐⚪⚪⚪⚪⚪
  ⚪⚪⚪⚪🍐🍐🌚🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌚🍐⚪⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌚🌳⚪⚪⚪⚪⚪
  ⚪⚪⚪🍐⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🍐🌳⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫🍐⚪⚪⚪⚪
  ⚪⚪⚪🍐⚫⚫🌚🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫🍐⚪⚪⚪⚪
  ⚪⚪⚪🍐🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫⚪⚪⚪⚪
  ⚪⚪⚪⚪🍐🍐⚫⚫🌚🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌚⚫🍐⚪⚪⚪
  ⚪⚪⚪⚪⚪🍐⚫⚫⚫🌚🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌚🍐🍐🍐⚪⚪⚪⚪
  ⚪⚪⚪⚪🌳🍐🍐⚫⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌚🌼⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫🍐🍐⚪⚪⚪⚪⚪⚪
  ⚪⚪⚪⚪🍐⚫🍐🍐🌳🌳⚫🌼🌼🌼🌼🌼⚫🌸🌸🌸🌸🐷🌼🌼🌼🌼🌼🌼🌼🌼⚫🍐⚫🍐⚪⚪⚪⚪⚪⚪⚪⚪
  ⚪⚪⚪🍐⚫🌼🌕🌼🌼⚫⚫⚫⚫🌼🌚⚫🌸🌸🌸🌸🌸🌸🐷🐷🌼🌼🌼🌼🌚⚫🍐🍐⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
  ⚪⚪⚪⚫⚫🌼🌼🌼🌕🌕🌼⚫🌚⚫⚫🌸🌸🌸🌸🌸🌸🌚🌸🌸🌸🌼🌼⚫🍐🍐🌳🌳🌳⚪⚪⚪⚪⚪⚪⚪⚪⚪
  ⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🍓🍓🌸🌸🌸🌸🌸🌼🌚🌸🌸⚫⚫🍐🍐🍐🍐🍐⚫⚫🍐🍐🌳⚪⚪⚪⚪⚪
  ⚪⚪🍐⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫🍓🍓🍓🌸🌸⚫🌸⚫🌚🌸🌸⚫🌼🌚🌼⚫🌼🌼🌕🌼🌼⚫🍐🍐⚪⚪⚪⚪
  ⚪⚪🍐⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫🍓🍓🍓🍓🍓🌸🌸🌸🌸🌸🌸⚫🌼🌼🌼🌼🌼🌼🌼🌕🌼🌼⚫🍐⚪⚪⚪⚪
  ⚪⚪🌳⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫🍓🍓🍓🍓🍓🌸🌸⚫🌼🌸🌸⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕🌚🍐⚪⚪⚪⚪
  ⚪⚪⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌚🍓🍓🍓🍓⚫⚫⚫⚫🌼🌸🌸🌚🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕🌚🍐⚪⚪⚪⚪
  ⚪⚪⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌚🍓🍓🍓🍓🍓⚫⚫⚫🌚🌸🍓🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🍐⚪⚪⚪⚪
  ⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼⚫⚫⚫🌚🍓🍓🍓🍓⚫⚫⚫🌚🌸🌚🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🍐⚪⚪⚪⚪
  ⚪🍐⚫⚫🌚🌼⚫⚫🌳🍐🍐🌳🌚🌼🌼🌚🍓🍓🍓🍓🍓🍓🍓🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🍐⚪⚪⚪⚪
  ⚪🍐⚫⚫🌳🍐🍐⚫🍐🍐🌼🌼🌼🌼🌼🌼⚫🌚🍓🍓🍓🌚🌚🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌳⚪⚪⚪⚪
  ⚪⚪🍐🌚🍐🍐🍐⚫🌚⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫⚪⚪⚪⚪
  ⚪⚪⚪⚪⚪🍐⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫⚪⚪⚪⚪
  ⚪⚪⚪⚪⚪⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫🌳⚪⚪⚪
  ⚪⚪⚪⚪🍐⚫🌚🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫🍐⚪⚪⚪
  ⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫🍐⚪⚪⚪
  ⚪⚪⚪⚪🍐🍐⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫🍐⚪⚪⚪
  ⚪⚪⚪⚪⚪🍐⚫⚫⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌳🍐⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫🍐⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪🌳🍐🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌚🍐⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕🌼🍐⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪🍐🍐⚫⚫⚫🌼🌼🌼🌼🌼⚫🍐⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🍐⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫⚫⚫⚫🌼🌼🌕⚫⚪⚪🌳🌳⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🍐⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐🍐🌳⚫⚫🌼🌼🌼⚫⚪⚪⚪🌳⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🍐⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫⚫⚫⚫🍐⚪⚪⚪🍐⚫⚫🌚🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫⚫🍐⚪⚪⚪⚪⚪⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐🌳🍐🍐⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼💭⚫⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫🍐⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫🍐⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌕⚫🍐⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌚🍐⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🍐⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🌳⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🍐⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼🌼🍐⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌚🌼🌼🌼🌼🌼🌼🌼🌼🌼🍐⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼🌼⚫⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼⚫⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼⚫⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌼⚫🍐⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼⚫🍐⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼⚫🍐⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🌚🍐⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚫⚫⚫🌼🌼🌼🌼🌼🌼🌼🍐⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼🌼🍐⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫⚫🌼🌼🌼🌼🌼🌼🍐⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🌳⚫⚫🌼🌼🌼🌼🌼🌼🍐⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼🌼⚫⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫⚫🌼🌼🌼🌼🌼⚫⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌼🌼🌼🌼🌼⚫⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫🌚🌼🌼⚫🌼⚫⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫⚫⚫⚫⚫⚫⚫🍐⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🌳⚫⚫⚫⚫⚫⚫🌳⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪🍐⚫🍐🍐🍐🍐🍐⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
*/
