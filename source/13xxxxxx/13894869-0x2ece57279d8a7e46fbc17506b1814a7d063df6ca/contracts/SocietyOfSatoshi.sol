// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SocietyOfSatoshi is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public constant maxTokens = 10000;
    uint256[5] public mintPrice = [
        10000000 ether,
        15000000 ether,
        20000000 ether,
        30000000 ether,
        50000000 ether
    ];

    bool public mintStarted = true;
    uint256 public batchLimit = 5;
    string public baseURI =
        "https://satoshi.mypinata.cloud/ipfs/QmZqZ5dfSQMtkmioUHpbHzGywWw4LtkuQb3BHEivoCrMXw";

    IERC20 public sosToken;

    constructor(address sosTokenAddress) ERC721("SocietyOfSatoshi", "SOS") {
        sosToken = IERC20(sosTokenAddress);
    }

    function mint(uint256 tokensToMint) public payable {
        uint256 supply = totalSupply();
        require(mintStarted, "Mint is not started");
        require(tokensToMint <= batchLimit, "Not in batch limit");
        require(
            (supply % 2000) + tokensToMint <= 2000,
            "Minting crosses price bracket"
        );
        require(
            supply.add(tokensToMint) <= maxTokens,
            "Minting exceeds supply"
        );

        uint256 cost = tokensToMint.mul(
            mintPrice[uint256(supply) / uint256(2000)]
        );
        uint256 allowance = sosToken.allowance(msg.sender, address(this));
        require(allowance >= cost, "Not enough allowance of SOS");

        sosToken.transferFrom(msg.sender, address(this), cost);

        for (uint16 i = 1; i <= tokensToMint; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function withdraw() public onlyOwner {
        sosToken.transfer(owner(), sosToken.balanceOf(address(this)));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function startMint() external onlyOwner {
        mintStarted = true;
    }

    function pauseMint() external onlyOwner {
        mintStarted = false;
    }

    function reserveSOS(uint256 numberOfMints) public onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 i = 1; i <= numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
}

