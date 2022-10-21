//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EmpireDrops is ERC1155(""), Ownable {

    address public ETHEREAN_EMPIRE_CONTRACT_ADDRESS;
    bool public MINT_ACTIVE = false;

    constructor(address _contractAddress){
        ETHEREAN_EMPIRE_CONTRACT_ADDRESS = _contractAddress;
    }

    function setEthereanEmpireContractAddress(address _contractAddress) external onlyOwner {
        ETHEREAN_EMPIRE_CONTRACT_ADDRESS = _contractAddress;
    }

    function setURI(string memory _baseURI) external onlyOwner {
        _setURI(_baseURI);
    }
    
    function flipMintActive() external onlyOwner {
        MINT_ACTIVE = !MINT_ACTIVE;
    }

    function mint(address _minter, uint _dropId) external {
        require(msg.sender == ETHEREAN_EMPIRE_CONTRACT_ADDRESS, "Can only mint through Etherean Empire mintDrop function.");
        require(MINT_ACTIVE == true, "Minting is not active.");
        _mint(_minter, _dropId, 1, "");
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function recoverERC20(address _tokenAddress, uint _tokenAmount) public onlyOwner {
        IERC20(_tokenAddress).transfer(owner(), _tokenAmount);
    }

    function recoverERC721(address _tokenAddress, uint _tokenId) public onlyOwner {
        IERC721(_tokenAddress).safeTransferFrom(address(this), owner(), _tokenId);
    }

}
