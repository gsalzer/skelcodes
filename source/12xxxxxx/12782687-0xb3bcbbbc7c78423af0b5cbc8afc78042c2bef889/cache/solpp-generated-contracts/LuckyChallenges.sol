pragma solidity >0.6.1 <0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LuckyChallenges is ERC721, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    bool public isLocked = false;
    string public provenance;

    constructor() public ERC721("LuckyChallenges", "LMC") {
        _setBaseURI("https://luckymaneki.com/token/challenges/");
    }

    // God Mode

    function sendReward(address recipient) public onlyOwner {
        require(!isLocked, "Contract Locked");
        _safeMint(recipient, totalSupply());
    }

    function lockMint() public onlyOwner {
        isLocked = true;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setProvenance(string memory p) public onlyOwner {
        provenance = p;
    }
}
