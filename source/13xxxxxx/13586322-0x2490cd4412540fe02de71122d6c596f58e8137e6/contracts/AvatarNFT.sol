// SPDX-License-Identifier: MIT
// Adapted from World of Women: https://etherscan.io/token/0xe785e82358879f061bc3dcac6f0444462d4b5330#readContract
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Want to launch your own collection ? Check out https://buildship.dev
contract AvatarNFT is ERC721, ERC721Enumerable, Ownable {

    uint256 internal _price; // = 0.03 ether;
    uint256 internal _reserved; // = 200;

    uint256 public MAX_SUPPLY; // = 10000;
    uint256 public MAX_TOKENS_PER_MINT; // = 20;

    uint256 public startingIndex;

    address payable beneficiary;

    bool private _saleStarted;

    string public PROVENANCE_HASH = "";
    string public baseURI;

    constructor(
        uint256 _startPrice, uint256 _maxSupply,
        uint256 _nReserved,
        uint256 _maxTokensPerMint,
        string memory _uri,
        string memory _name, string memory _symbol
    ) ERC721(_name, _symbol) {
        _price = _startPrice;
        _reserved = _nReserved;
        MAX_SUPPLY = _maxSupply;
        MAX_TOKENS_PER_MINT = _maxTokensPerMint;
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata uri) public onlyOwner {
        baseURI = uri;
    }

    function setBeneficiary(address payable _beneficiary) public virtual onlyOwner {
        // require non set
        require(beneficiary == address(0));

        beneficiary = _beneficiary;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier whenSaleStarted() {
        require(_saleStarted, "Sale not started");
        _;
    }

    function mint(uint256 _nbTokens) whenSaleStarted public payable virtual {
        uint256 supply = totalSupply();
        require(_nbTokens <= MAX_TOKENS_PER_MINT, "You cannot mint more than MAX_TOKENS_PER_MINT tokens at once!");
        require(supply + _nbTokens <= MAX_SUPPLY - _reserved, "Not enough Tokens left.");
        require(_nbTokens * _price <= msg.value, "Inconsistent amount sent!");

        for (uint256 i; i < _nbTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function flipSaleStarted() external onlyOwner {
        require(beneficiary != address(0), "Beneficiary not set");

        _saleStarted = !_saleStarted;

        if (_saleStarted && startingIndex == 0) {
            setStartingIndex();
        }
    }

    function saleStarted() public view returns(bool) {
        return _saleStarted;
    }

    // Make it possible to change the price: just in case
    function setPrice(uint256 _newPrice) external virtual onlyOwner {
        _price = _newPrice;
    }

    function getPrice() public view virtual returns (uint256){
        return _price;
    }

    function getReservedLeft() public view virtual returns (uint256) {
        return _reserved;
    }

    // This should be set before sales open.
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE_HASH = provenanceHash;
    }

    // Helper to list all the tokens of a wallet
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function claimReserved(uint256 _number, address _receiver) external onlyOwner virtual {
        require(_number <= _reserved, "That would exceed the max reserved.");

        uint256 _tokenId = totalSupply();
        for (uint256 i; i < _number; i++) {
            _safeMint(_receiver, _tokenId + i);
        }

        _reserved = _reserved - _number;
    }

    function setStartingIndex() public virtual {
        require(startingIndex == 0, "Starting index is already set");

        // BlockHash only works for the most 256 recent blocks.
        uint256 _block_shift = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        _block_shift =  1 + (_block_shift % 255);

        // This shouldn't happen, but just in case the blockchain gets a reboot?
        if (block.number < _block_shift) {
            _block_shift = 1;
        }

        uint256 _block_ref = block.number - _block_shift;
        startingIndex = uint(blockhash(_block_ref)) % MAX_SUPPLY;

        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    function withdraw() public virtual onlyOwner {
        require(beneficiary != address(0), "Beneficiary not set");

        uint256 _balance = address(this).balance;

        require(payable(beneficiary).send(_balance));
    }

    function DEVELOPER() public pure returns (string memory _url) {
        _url = "https://buildship.dev";
    }

    function DEVELOPER_ADDRESS() public pure returns (address payable _dev) {
        _dev = payable(0x704C043CeB93bD6cBE570C6A2708c3E1C0310587);
    }
}

