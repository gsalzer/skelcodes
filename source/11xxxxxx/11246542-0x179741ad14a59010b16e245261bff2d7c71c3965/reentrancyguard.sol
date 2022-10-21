// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract ReentrancyGuard {
	uint private constant _NOT_ENTERED = 1;
	uint private constant _ENTERED = 2;
	uint private _status;
	constructor () public {
		_status = _NOT_ENTERED;
	}
	modifier nonReentrant() {
		require(_status != _ENTERED, "reentrant call");
		_status = _ENTERED;
		_;
		_status = _NOT_ENTERED;
	}
}
