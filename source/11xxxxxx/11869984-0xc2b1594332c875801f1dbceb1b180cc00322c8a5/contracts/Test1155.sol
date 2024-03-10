pragma solidity ^0.6.0;

import "@openzeppelin/contracts/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Test1155 is ERC1155PresetMinterPauser, Ownable {
    constructor()
        public
        // start contract
        ERC1155PresetMinterPauser("https://ck.io/api/")
    {}

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setURI(baseURI_);
    }
}

