pragma solidity ^0.8.4;
//import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

//import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import "./erc721enum.sol";

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
// import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Full.sol";
// import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Mintable.sol";

interface ContractInterface {
    function balanceOf(address owner) external view returns (uint256 number);
}

contract NFZv2 is OwnableUpgradeable, ERC721EnumerableUpgradeable {
    uint256 constant MAX_INIT_SUPPLY = 4444;
    uint256 constant MAXSUPPLY = 6666;

    bool public isPresale;
    bool public isLaunched;
    bytes32 private Whitelist_Root;

    bytes32 private HalfMintRoot;
    bytes32 private uniCandyRoot;
    uint256 private value;

    string baseURI;
    mapping(address => bool) public preSaleMapping;

    //Where your zombie goes will be stored on the blockchain
    //coming in phase 2.0
    mapping(uint256 => Locations[]) public passport;
    struct Locations {
        string locationName;
        uint256 locationId;
    }

    mapping(address => bool) public claimMapping;

    uint256 public MINT_PRICE;
    bytes32 private freeClaimRoot;

    //init function called on deploy

    function init(
        bytes32 wlroot,
        bytes32 hmroot,
        string memory _base
    ) public initializer {
        isPresale = false;
        isLaunched = false;
        Whitelist_Root = wlroot;
        HalfMintRoot = hmroot;
        __ERC721_init("Nice Fun Zombies", "NFZ");
        __ERC721Enumerable_init();
        __Ownable_init();

        baseURI = _base;
    }

    function giveways(address[] memory freeNFZ) external onlyOwner {
        uint256 counter = totalSupply();
        for (uint256 i = 1; i <= freeNFZ.length; i++) {
            address winner = freeNFZ[i - 1];
            _safeMint(winner, counter + i);
        }
    }

    //owner can mint after deploy
    function teamMint(uint256 amount) external onlyOwner {
        uint256 counter = totalSupply();

        for (uint256 i = 1; i < amount + 1; i++) {
            _safeMint(msg.sender, counter + i);
        }
    }

    //to toggle general sale
    function launchToggle() public onlyOwner {
        isLaunched = !isLaunched;
    }

    //to toggle presale
    function presaleToggle() public onlyOwner {
        isPresale = !isPresale;
    }

    function setMintPrice(uint256 _price) public onlyOwner {
        MINT_PRICE = _price;
    }

    function claim() public {}

    function freeClaim(
        address account,
        uint256 _mintAmount,
        bytes32[] calldata proof
    ) external {
        require(isLaunched, "Minting is off");
        require(
            MerkleProofUpgradeable.verify(proof, freeClaimRoot, _leaf(account)),
            "account not part of claim list"
        );
        require(
            _mintAmount <= (balanceOf(account) * 2),
            "Trying to claim too many"
        );
        require(_mintAmount < 101);
        require(!claimMapping[account], "already claimed");

        uint256 counter = totalSupply();
        for (uint256 i = 1; i < _mintAmount + 1; i++) {
            _safeMint(account, counter + i);
        }
        claimMapping[account] = true;
    }

    //general mint function - checks to make sure launch = true;
    function mint(address account, uint256 _mintAmount) external payable {
        uint256 counter = totalSupply();
        require(isLaunched, "general mint has not started");
        require(
            counter + _mintAmount < MAX_INIT_SUPPLY,
            "exceeds contract limit"
        );

        require(
            msg.value >= MINT_PRICE * _mintAmount,
            "Not enough eth sent: check price"
        );
        require(_mintAmount < 11, "Only mint 10. Leave some for the rest!");

        for (uint256 i = 1; i < _mintAmount + 1; i++) {
            _safeMint(account, counter + i);
        }
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.nicefunzombies.io/contract";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function updateMerkleRoot(string memory rootType, bytes32 root)
        external
        onlyOwner
    {
        if (
            keccak256(abi.encodePacked(rootType)) ==
            keccak256(abi.encodePacked("freeClaimRoot"))
        ) {
            freeClaimRoot = root;
        } else {
            revert("Incorrect rootType");
        }
    }
}

