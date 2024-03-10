// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

import "../standard/ERC721/ERC721Holder.sol";
import "../standard/ERC1155/ERC1155Receiver.sol";
import "../standard/ERC721/IERC721.sol";
import "../standard/ERC777/IERC777.sol";
import "../standard/ERC1155/IERC1155.sol";
import "../standard/ERC20/IERC20.sol";
import "./ETHRecipient.sol";

contract TokenManager is ETHRecipient, ERC721Holder, ERC1155Receiver {
	function _sendETH(address payable to, uint256 amount) internal {
		to.transfer(amount);
	}

	function _sendERC20(
		address token,
		address to,
		uint256 amount
	) internal {
		require(IERC20(token).transfer(to, amount), "ERC20 transfer failed");
	}

	function _sendERC721(
		address token,
		address to,
		uint256 tokenId
	) internal {
		IERC721(token).safeTransferFrom(address(this), to, tokenId);
	}

	function _sendERC777(
		address token,
		address recipient,
		uint256 amount,
		bytes memory data
	) internal {
		IERC777(token).send(recipient, amount, data);
	}

	function _sendERC1155(
		address token,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal {
		IERC1155(token).safeTransferFrom(address(this), to, id, amount, data);
	}
}

