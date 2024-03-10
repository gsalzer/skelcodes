// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CryptoDads is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_DADS = 10000;
    uint256 public constant PRICE = 0.07 ether;
    uint256 public constant MAX_PER_MINT = 5;
    uint256 public constant PRESALE_MAX_MINT = 3;
    uint256 public constant RESERVED_DADS = 200;
    address public constant founderAddress = 0x501CaE10986556F99e28eDf50E213E4cA871d600;
    address public constant devAddress = 0xd7bC08Fa2852ad76138B7757740a3934ce5F0A45;

    bool public reservedClaimed;

    uint256 public numDadsMinted;

    string public baseTokenURI;

    bool public publicSaleStarted;
    bool public presaleStarted;

    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _presaleClaimed;

    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfDads);
    event PublicSaleMint(address minter, uint256 amountOfDads);

    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale has not started");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale has not started");
        _;
    }

    constructor(string memory baseURI) ERC721("CryptoDads", "DAD") {
        baseTokenURI = baseURI;
    }

    function claimReserved(address recipient) external onlyOwner {
        require(!reservedClaimed, "Already have claimed reserved dads");
        require(recipient != address(0), "Cannot add null address");
        require(totalSupply() < MAX_DADS, "All tokens have been minted");
        require(totalSupply() + RESERVED_DADS <= MAX_DADS, "Minting would exceed max supply");

        uint256 _nextTokenId = numDadsMinted + 1;

        for (uint256 i = 0; i < RESERVED_DADS; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }
        numDadsMinted += RESERVED_DADS;
        reservedClaimed = true;
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _presaleEligible[addresses[i]] = true;

            _presaleClaimed[addresses[i]] > 0 ? _presaleClaimed[addresses[i]] : 0;
        }
    }

    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return _presaleEligible[addr];
    }

    function presaleAmountClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Cannot add null address");

        return _presaleClaimed[owner];
    }

    function mintPresale(uint256 amountOfDads) external payable whenPresaleStarted {
        require(_presaleEligible[msg.sender], "You are not eligible for the presale");
        require(totalSupply() < MAX_DADS, "All tokens have been minted");
        require(amountOfDads <= PRESALE_MAX_MINT, "Cannot purchase this many tokens during presale");
        require(totalSupply() + amountOfDads <= MAX_DADS, "Minting would exceed max supply");
        require(_presaleClaimed[msg.sender] + amountOfDads <= PRESALE_MAX_MINT, "Purchase exceeds max allowed");
        require(amountOfDads > 0, "Must mint at least one dad");
        require(PRICE * amountOfDads == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfDads; i++) {
            uint256 tokenId = numDadsMinted + 1;

            numDadsMinted += 1;
            _presaleClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PresaleMint(msg.sender, amountOfDads);
    }

    function mint(uint256 amountOfDads) external payable whenPublicSaleStarted {
        require(totalSupply() < MAX_DADS, "All tokens have been minted");
        require(amountOfDads <= MAX_PER_MINT, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + amountOfDads <= MAX_DADS, "Minting would exceed max supply");
        require(amountOfDads > 0, "Must mint at least one dad");
        require(PRICE * amountOfDads == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfDads; i++) {
            uint256 tokenId = numDadsMinted + 1;

            numDadsMinted += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amountOfDads);
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
        _widthdraw(devAddress, ((balance * 15) / 100));
        _widthdraw(founderAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}

