// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @author Roi Di Segni (@sheeeev66)
 * @title Skeleton Keys
 */

import "./ERC721.sol";
import "./IERC20.sol";

contract SKeys is ERC721 {

    bool public walletLimit = true;

    uint16 private _tokenId;

    IERC20 Old; // = IERC20(0xb849C1077072466317cE9d170119A6e68C0879E7);

    constructor() ERC721("Skeleton Keys", "SKEYS") { }

    function setOldCOntract(address _address) external onlyOwner {
        Old = IERC20(_address);
    }

    /**
     * @dev migrates tokens from the old contract to the new one
     */
    function migrateSKEYS() external {
        require(Old.allowance(msg.sender, address(this)) > 0, "Contract address is not approved!");

        _safeMint(msg.sender, _tokenId);
        _tokenId++;
        
        require(Old.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, 1), "Could not transfer tokens to the burn address!");
    }

    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        if (walletLimit) require(balanceOf(to) + 1 <= 3, "SKEYS: Cannot hold more than 3 SKEYS per wallet");
        super._transfer(from, to, tokenId);
    }

    function emergencyFlipWalletLimit() external onlyOwner {
        walletLimit = !walletLimit;
    }

    function totalSupply() external view returns(uint) {
        return _tokenId;
    }

}
