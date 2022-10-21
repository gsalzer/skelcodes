// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

import "./Spawner.sol";

contract Factory is Spawner {
	event InstanceCreated(address instance, address template);

	function create(address template, bytes memory args) public returns (address instance) {
		instance = Spawner._spawn(msg.sender, template, args);
		emit InstanceCreated(instance, template);
	}

	function createSalty(
		address template,
		bytes memory args,
		bytes32 salt
	) public returns (address instance) {
		instance = Spawner._spawnSalty(msg.sender, template, args, salt);
		emit InstanceCreated(instance, template);
	}
}

