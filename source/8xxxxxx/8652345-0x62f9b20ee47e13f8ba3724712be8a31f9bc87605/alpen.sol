pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Detailed.sol";

contract ALPENt is ERC20, Ownable, ERC20Detailed("Alpen", "ALPEN", 18) {
	/**
		* @dev Destroys `amount` tokens from the caller.
		*
		* See {ERC20-_burn}.
		*/
	function burn(uint256 amount) public onlyOwner {
		_burn(_msgSender(), amount);
	}

	/**
		* @dev See {ERC20-_burnFrom}.
		*/
	function burnFrom(address account, uint256 amount) public onlyOwner {
		_burnFrom(account, amount);
	}

	/**
		* @dev See {ERC20-_mint}.
		*
		* Requirements:
		*
		* - the caller must be the {Owner}.
		*/
	function mintTo(address account, uint256 amount) public onlyOwner returns (bool) {
		_mint(account, amount);
		return true;
	}

	/**
		* @dev See {ERC20-_mint}.
		*
		* Requirements:
		*
		* - the caller must be the {Owner}.
		*/
	function mint(uint256 amount) public onlyOwner returns (bool) {
		_mint(_msgSender(), amount);
		return true;
	}

	/**
	* @dev Owner can transfer out any accidentally sent ERC20 tokens.
	*/
	function transferAnyERC20Token(address tokenAddress, uint256 amount) public onlyOwner returns (bool) {
		return ERC20(tokenAddress).transfer(owner(), amount);
	}
}
