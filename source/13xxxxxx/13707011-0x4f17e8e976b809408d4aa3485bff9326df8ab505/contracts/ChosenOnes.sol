// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/*
 █     █░ ▒█████   ██▀███    ██████  ██░ ██  ██▓ ██▓███
▓█░ █ ░█░▒██▒  ██▒▓██ ▒ ██▒▒██    ▒ ▓██░ ██▒▓██▒▓██░  ██▒
▒█░ █ ░█ ▒██░  ██▒▓██ ░▄█ ▒░ ▓██▄   ▒██▀▀██░▒██▒▓██░ ██▓▒
░█░ █ ░█ ▒██   ██░▒██▀▀█▄    ▒   ██▒░▓█ ░██ ░██░▒██▄█▓▒ ▒
░░██▒██▓ ░ ████▓▒░░██▓ ▒██▒▒██████▒▒░▓█▒░██▓░██░▒██▒ ░  ░
░ ▓░▒ ▒  ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒░▓  ▒▓▒░ ░  ░
  ▒ ░ ░    ░ ▒ ▒░   ░▒ ░ ▒░░ ░▒  ░ ░ ▒ ░▒░ ░ ▒ ░░▒ ░
  ░   ░  ░ ░ ░ ▒    ░░   ░ ░  ░  ░   ░  ░░ ░ ▒ ░░░
    ░        ░ ░     ░           ░   ░  ░  ░ ░
  by @nichosystem
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Mintable.sol";

contract ChosenOnes is ERC721Enumerable, Ownable, Mintable {
    using Strings for uint256;
    using ECDSA for bytes32;

    event Mint(address indexed _to, uint256 indexed _id);
    event ToggleSale(bool saleLive, bool presaleLive);

    address public constant SIGNER = 0x78dF3aC8Bb88eF068A5A0D709f53Dedbd9D1964d;
    address public constant VAULT = 0xDDA119Aa6Da912C62428a5A37Ed5541CB87e32a7;
    uint256 public constant MAX_SUPPLY = 11111;
    uint256 public constant TX_LIMIT = 20;

    uint256 public supply;
    uint256 public price;
    uint256 public batchSupply;
    uint256 public giftedAmount;
    bool public saleLive;
    bool public presaleLive;
    string public baseURI;

    mapping(address => uint256) public presaleTokensClaimed;
    mapping(address => mapping(uint256 => bool)) private _usedNonces;

    constructor(address _owner, address _imx)
        ERC721("ChosenOnes", "ONES")
        Mintable(_owner, _imx)
    {}

    // INTERNAL
    function _mintFor(
        address to,
        uint256 id,
        bytes memory blueprint
    ) internal override {
        _safeMint(to, id);
    }

    function _hashTransaction(
        address sender,
        uint256 qty,
        uint256 nonce
    ) private pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(sender, qty, nonce))
                .toEthSignedMessageHash();
    }

    function _matchSigner(bytes32 hash, bytes memory signature)
        private
        pure
        returns (bool)
    {
        return SIGNER == hash.recover(signature);
    }

    // ONLY OWNER
    function toggleSale(bool _saleLive, bool _presaleLive) external onlyOwner {
        saleLive = _saleLive;
        presaleLive = _presaleLive;
        emit ToggleSale(_saleLive, _presaleLive);
    }

    function setupBatch(uint256 _price, uint256 _batchSupply)
        external
        onlyOwner
    {
        price = _price;
        batchSupply = _batchSupply;
    }

    function gift(address[] calldata recipients) external onlyOwner {
        require(supply + recipients.length <= MAX_SUPPLY, "Exceeds max supply");
        uint256 _supply = supply; // Gas optimization
        giftedAmount += recipients.length;
        supply += recipients.length;
        // zero-index i for recipients array
        for (uint256 i = 0; i < recipients.length; i++) {
            emit Mint(recipients[i], _supply + i + 1); // increment by 1 for token IDs
        }
    }

    function withdraw() external onlyOwner {
        payable(VAULT).transfer(address(this).balance);
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    // PUBLIC
    function mint(uint256 tokenQuantity) external payable {
        require(saleLive, "Sale closed");
        require(
            supply + tokenQuantity <= batchSupply &&
                supply + tokenQuantity <= MAX_SUPPLY,
            "Exceeds max supply"
        );
        require(tokenQuantity <= TX_LIMIT, "Exceeds transaction limit");
        require(tokenQuantity > 0, "No tokens issued");
        require(msg.value >= price * tokenQuantity, "Insufficient ETH");

        uint256 _supply = supply; // Gas optimization
        supply += tokenQuantity;
        for (uint256 i = 1; i <= tokenQuantity; i++) {
            emit Mint(msg.sender, _supply + i);
        }
    }

    function presaleMint(
        bytes32 hash,
        bytes memory signature,
        uint256 nonce,
        uint256 tokenQuantity
    ) external payable {
        require(presaleLive, "Presale closed");
        require(
            supply + tokenQuantity <= batchSupply &&
                supply + tokenQuantity <= MAX_SUPPLY,
            "Exceeds presale supply"
        );
        require(tokenQuantity > 0, "No tokens issued");
        require(msg.value >= price * tokenQuantity, "Insufficient ETH");
        require(_matchSigner(hash, signature), "No direct mint");
        require(!_usedNonces[msg.sender][nonce], "Hash used");
        require(
            _hashTransaction(msg.sender, tokenQuantity, nonce) == hash,
            "Hash fail"
        );

        presaleTokensClaimed[msg.sender] += tokenQuantity;
        _usedNonces[msg.sender][nonce] = true;
        uint256 _supply = supply; // Gas optimization
        supply += tokenQuantity;
        for (uint256 i = 1; i <= tokenQuantity; i++) {
            emit Mint(msg.sender, _supply + i);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}

