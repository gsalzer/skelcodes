// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Ownable, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
	 
	event AddToWhiteList(address _address);
    event RemovedFromWhiteList(address _address);
	event WhiteListMultipleAddress(address[] accounts);
    event RemoveWhiteListedMultipleAddress(address[] accounts);
	mapping (address => bool) public isWhiteListed;
	
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (_msgSender() != owner()) {
            require(!paused(), "ERC721Pausable: token transfer while paused");
        }
    }
	
	function whiteListAddress(address _address) public onlyOwner{
	   isWhiteListed[_address] = true;
	   emit AddToWhiteList(_address);
    }
	
	function removeWhiteListedAddress (address _address) public onlyOwner{
	   isWhiteListed[_address] = false;
	   emit RemovedFromWhiteList(_address);
	}
	
	function whiteListMultipleAddress(address[] calldata accounts) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++){
			isWhiteListed[accounts[i]] = true;
        }
        emit WhiteListMultipleAddress(accounts);
    }
	
	function removeWhiteListedMultipleAddress(address[] calldata accounts) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++){
			isWhiteListed[accounts[i]] = false;
        }
		emit RemoveWhiteListedMultipleAddress(accounts);
    }
}
