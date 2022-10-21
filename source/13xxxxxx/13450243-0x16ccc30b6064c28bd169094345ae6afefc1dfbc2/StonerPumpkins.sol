// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract StonerPumpkins is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_NFTS = 10000;
    uint256 public constant PRICE = 0.042 ether;
    uint256 public constant MAX_PER_MINT = 10;
    uint256 public constant PRESALE_MAX_MINT = 5;
    uint256 public constant RESERVED_NFTS = 100;
    address public constant devAddress = 0xADDaF99990b665D8553f08653966fa8995Cc1209;
    address public constant team1Address = 0xFb5188B0aFc41da4B1086684a7F70Bf1f71b6681;
    address public constant team2Address = 0x3a63d9c8727C98b75372CF8d2315C84373De0253;

    uint256 public reservedClaimed;

    uint256 public numNftsMinted;

    string public baseTokenURI;

    bool public publicSaleStarted;
    bool public presaleStarted;

    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _totalClaimed;

    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfNfts);
    event PublicSaleMint(address minter, uint256 amountOfNfts);

    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale is not open yet");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale is not open yet");
        _;
    }

    constructor(string memory baseURI) ERC721("Stoner Pumpkins", "SP") {
        baseTokenURI = baseURI;
    }

    function claimReserved(address recipient, uint256 amount) external onlyOwner {
        require(reservedClaimed != RESERVED_NFTS, "You have already claimed all reserved nfts");
        require(reservedClaimed + amount <= RESERVED_NFTS, "Mint exceeds max reserved nfts");
        require(recipient != address(0), "Cannot add null address");
        require(totalSupply() < MAX_NFTS, "All NFTs have been minted");
        require(totalSupply() + amount <= MAX_NFTS, "Mint exceeds max supply");

        uint256 _nextTokenId = numNftsMinted + 1;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }
        numNftsMinted += amount;
        reservedClaimed += amount;
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _presaleEligible[addresses[i]] = true;

            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return _presaleEligible[addr];
    }

    function amountClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Cannot add null address");

        return _totalClaimed[owner];
    }

    function mintPresale(uint256 amountOfNfts) external payable whenPresaleStarted {
        require(_presaleEligible[msg.sender], "You are not whitelisted for the presale");
        require(totalSupply() < MAX_NFTS, "All NFTs have been minted");
        require(amountOfNfts <= PRESALE_MAX_MINT, "Purchase exceeds presale limit");
        require(totalSupply() + amountOfNfts <= MAX_NFTS, "Mint exceeds max supply");
        require(_totalClaimed[msg.sender] + amountOfNfts <= PRESALE_MAX_MINT, "Purchase exceeds max allowed");
        require(amountOfNfts > 0, "Must mint at least one NFT");
        require(PRICE * amountOfNfts == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfNfts; i++) {
            uint256 tokenId = numNftsMinted + 1;

            numNftsMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PresaleMint(msg.sender, amountOfNfts);
    }

    function mint(uint256 amountOfNfts) external payable whenPublicSaleStarted {
        require(totalSupply() < MAX_NFTS, "All NFTs have been minted");
        require(amountOfNfts <= MAX_PER_MINT, "Amount exceeds NFTs per transaction");
        require(totalSupply() + amountOfNfts <= MAX_NFTS, "Mint exceeds max supply");
        require(amountOfNfts > 0, "Must mint at least one NFT");
        require(PRICE * amountOfNfts == msg.value, "Amount of ETH is incorrect");

        for (uint256 i = 0; i < amountOfNfts; i++) {
            uint256 tokenId = numNftsMinted + 1;

            numNftsMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amountOfNfts);
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(devAddress, ((balance * 10) / 100));
        _widthdraw(team1Address, ((balance * 10) / 100));
        _widthdraw(team2Address, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}
