// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'hardhat/console.sol';

import '../utilities/MinterRole.sol';

contract RiddleBrain is ERC20, Ownable, MinterRole {
	string private _name;
	uint public constant initialSupply = 10000000000 * (10 ** 18);

	constructor() public ERC20('RiddleBrain', 'BRAIN') {
		// _mint(msg.sender, initialSupply);
	}

	function mint(address recepient, uint amount) public onlyMinter {
		_mint(recepient, amount);
	}

	function burn(address account, uint amount) external onlyMinter {
		_burn(account, amount);
	}

	function addMinter(address minter) public override onlyOwner {
		_addMinter(minter);
	}
}

