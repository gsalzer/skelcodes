// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import '../connectors/interfaces/IResetAccountConnector.sol';

contract FodlNFT is ERC721, Ownable {
    using Address for address;

    constructor(string memory name, string memory symbol) public ERC721(name, symbol) Ownable() {}

    function mint(address owner, uint256 nftId) external onlyOwner {
        _safeMint(owner, nftId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        address foldingAccount = address(tokenId);
        if (foldingAccount.isContract()) {
            IResetAccountConnector(foldingAccount).resetAccount(from, to, tokenId);
        }
    }
}

