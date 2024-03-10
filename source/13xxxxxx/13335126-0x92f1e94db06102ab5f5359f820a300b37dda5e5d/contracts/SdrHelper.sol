// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SdrHelper is Context {

	address immutable private sdrTokenAddress;

	modifier fromSdrToken {
		require(_msgSender() == sdrTokenAddress, "SDR Helper: only SDR token contract can call this function");
		_;
	}

	constructor(address sdrTokenAddress_) {
		sdrTokenAddress = sdrTokenAddress_;
	}

	function withdrawTokensSent(address tokenAddress) external fromSdrToken {
		IERC20 token = IERC20(tokenAddress);
		if (token.balanceOf(address(this)) > 0)
			token.transfer(_msgSender(), token.balanceOf(address(this)));
	}
}

