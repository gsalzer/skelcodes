pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT

// BUTTHEADSx@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&%,,,,,.,,,,,,#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@&&&%,,,,,,,,,,,,,,,,,,,,,%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@&&(,,,,,,.,,,,,,,,,,,,,,,,,,,&&@@@@@@@@@@&&&@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@&#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&@@@@@@@&&#  &&@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&/,,,,,,,,,.,,,,,,,,,,,,,,,.,,,,,,&&&@@&&&   #&@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@&&,,,,,,,,,,,,,,,,,,,,,,,,,,,#,,,,,,,*&&&  .#(/&&@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@&#,,,,,,,,,,.,,,,,,,,,,,,,&(%(,,,,,,,,,,%&*    (&@@@@@@@@@@@
// @@@@@@@@@&&@@@@@@@@@&#,,,,,,,,,,,,,,,,,,,,,,,,,,%&(,,,,,,,,,,,&&&&&&@@@@@@@@@@@@
// @@@@@@@@@&&(&&&&@@@@&&,,.,,,.,,,.,,,.,,,.,,,.,,,.,%&/,,,..   ,,&& .&&@@@@@@@@@@@
// @@@@@@@@@@&%    #&&&&&*,,,,,,,,,,,,,,,,,,,,,,,. .,,*&%,,,.    ,*&&&@@@@@@@@@@@@@
// @@@@@@@@@@@&&&&(.    *&&%,,,,,,,.,,,,,,,,,,,,     ,,*&*,,.    ,*&@@@@@@@@@@@@@@@
// @@@@@@@@@@@@&&*             .,,,,,,,,,,,,,,,,     ,,,&%,,    .,&&@@@@@@@@@@@@@@@
// @@@@@@@@@@@@&&&&&&&%          ,,.,,,,,,,,,,,.    .,,*&/,.  .,*&&@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&&   ,%&     /&,,,,,,,,,,,       ,,*&&,,,,,#&&@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@&&&&@&&,   &&#,.,,,,,,,,,.   .,,,&&*,/%&&&@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@&&&&@@@&&#,,,,,,,,,,,,,&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BUTTHEADSx is ERC721Enumerable, Ownable {
    string private _baseTokenURI = "";
    string private _contractURI = "";

    constructor() ERC721("BUTTHEADSx", "BHx") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function withdraw() public onlyOwner {
        uint256 _amount = address(this).balance;
        require(payable(_msgSender()).send(_amount));
    }
}

