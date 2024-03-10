// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC1155Receiver.sol";
import "../ERC165/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Receiver is ERC165, IERC1155Receiver {
	constructor() public {
		_registerInterface(
			ERC1155Receiver(0).onERC1155Received.selector ^ ERC1155Receiver(0).onERC1155BatchReceived.selector
		);
	}

	function onERC1155Received(
		address,
		address,
		uint256,
		uint256,
		bytes calldata
	) external virtual override returns (bytes4) {
		return this.onERC1155Received.selector;
	}

	function onERC1155BatchReceived(
		address,
		address,
		uint256[] calldata,
		uint256[] calldata,
		bytes calldata
	) external virtual override returns (bytes4) {
		return this.onERC1155BatchReceived.selector;
	}
}

