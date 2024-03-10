// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

contract PingPong {
	bool public val;

	function ping() public {
		val = true;
	}

	function pong() public {
		require(val, "not pongable");
		val = false;
	}
}

