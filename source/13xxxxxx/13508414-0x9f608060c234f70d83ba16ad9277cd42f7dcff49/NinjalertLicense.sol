// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import { MerkleProof } from "./MerkleProof.sol";


contract NinjalertsLifetimeNFT is ERC1155, Ownable {
    enum SaleStatus{STOPPED, WHITE_LIST, PUBLIC}
    using MerkleProof for bytes32[];
    SaleStatus public saleStatus;
    uint256 public tokensRemaining = 3529;
    uint256 public maxPublicMintPerTx = 5;
    uint256 public cost = 0.25 ether;
    uint256 public constant NINJALERT_NFT = 0;
    bytes32 merkleRoot1;
    bytes32 merkleRoot2;
    mapping (address => uint256) public whitelistMintCount;
    
    constructor() ERC1155("https://dknz9qml3u41j.cloudfront.net/ninjalerts/token/{id}.json") {
        saleStatus = SaleStatus.STOPPED;
    }
    
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function setWhitelist(bytes32 list1Root, bytes32 list2Root) public onlyOwner {
        merkleRoot1 = list1Root;
        merkleRoot2 = list2Root;
    }
    
    function startWhitelistSale(bytes32 list1Root, bytes32 list2Root) public onlyOwner {
        setWhitelist(list1Root, list2Root);
        saleStatus = SaleStatus.WHITE_LIST;
    }
    
    function startPublicSale() public onlyOwner {
        saleStatus = SaleStatus.PUBLIC;
    }
    
    function stopMint() public onlyOwner {
        saleStatus = SaleStatus.STOPPED;
    }
    
    modifier whiteList(bytes32 merkleRoot, bytes32[] memory proof) {
        require(saleStatus == SaleStatus.WHITE_LIST, "whitelist sale currently unavailable.");
        require(proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender))));
        _;
    }
    
    modifier mintable(uint256 amount) {
        require(amount>0,"amount must be positive integer.");
        require(msg.value >= amount * cost, "Ether insufficient.");
        require(amount <= tokensRemaining);
        _;
    }
    
    function mint(uint256 amount) internal {
        _mint(msg.sender, NINJALERT_NFT, amount, "");
        tokensRemaining -= amount; 
    }
    
    
    function whitelist1Mint(bytes32[] memory proof) public payable whiteList(merkleRoot1, proof) mintable(1) {
        require(whitelistMintCount[msg.sender] == 0, "You have already minted");
        whitelistMintCount[msg.sender] += 1;
        mint(1); 
    }
    
    function whitelist2Mint(uint256 amount, bytes32[] memory proof) public payable whiteList(merkleRoot2, proof) mintable(amount) {
        require(whitelistMintCount[msg.sender] + amount <=2, "You have already minted");
        whitelistMintCount[msg.sender] += amount;
        mint(amount);
    }
    
    function publicMint(uint256 amount) public payable mintable(amount) {
        require(saleStatus == SaleStatus.PUBLIC, "public sale currently unavailable.");
        require(amount <= maxPublicMintPerTx, "You can mint at most 20 times per transaction.");
        mint(amount);
    }
    
    function devMint(uint256 amount, address targetAddress) public onlyOwner {
        require(amount <= tokensRemaining);
        _mint(targetAddress, NINJALERT_NFT, amount, "");
        tokensRemaining -= amount;
    }
    
    function setURI(string memory uri_) public onlyOwner {
        _setURI(uri_);
    }
}
