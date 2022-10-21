// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ISTKBrightToken is IERC20Upgradeable {
	function mint(address account, uint256 amount) external;

	function burn(address account, uint256 amount) external;
}

