// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @author Roi Di Segni (aka @sheeeev66)
 */

import './ERC721.sol';

contract PugApeMintPass is ERC721 {

    address pugApesContractAddress;

    uint16 private _tokenId;

    mapping(address => uint) addressToMintPassId;

    IERC721 pugApesContract = IERC721(pugApesContractAddress);

    constructor() ERC721("PugApe Society Mint Pass", "PUGAPESMP") { }

    function setPugApesContractAddress(address _address) external onlyOwner {
        pugApesContractAddress = _address;
    }

    function buyMintPass() external payable {
        require(
            balanceOf(msg.sender) == 0 &&
            pugApesContract.balanceOf(msg.sender) == 0,
            "Only one mint pas per user!"
        );
        uint16 id = _tokenId;
        require(msg.value == 1 /* some price */, "Ether amount sent is not correct!");
        require(id < 400, "Mint passes sold out!"); // add a way to set the reserve according to how many mint passes were minted
        _mint(msg.sender, id);
        addressToMintPassId[msg.sender] = id;
        _tokenId++;
    }

    function _burnMintPass(address _address) external {
        require(msg.sender == pugApesContractAddress);
        _burn(addressToMintPassId[_address]);
        delete addressToMintPassId[_address];
    }
}
