// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

import "./IERC1616.sol";
import "../ERC165/ERC165.sol";

abstract contract ERC1616 is ERC165, IERC1616 {
	constructor() public {
		ERC165._registerInterface(0x5f46473f);
	}

	function hasAttribute(address account, uint256 attributeTypeID) external virtual override view returns (bool);

	function getAttributeValue(address account, uint256 attributeTypeID)
		external
		virtual
		override
		view
		returns (uint256);

	function countAttributeTypes() external virtual override view returns (uint256);

	function getAttributeTypeID(uint256 index) external virtual override view returns (uint256);
}

