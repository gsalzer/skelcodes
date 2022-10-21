// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

import "../lib/SafeMath.sol";

contract MetaTxUtils {
	using SafeMath for uint256;

	/// @dev Get the chain ID constant.
	/// @return chainId The chain id.
	function getChainId() public pure returns (uint256 chainId) {
		assembly {
			chainId := chainid()
		}
		return chainId;
	}

	/// @notice Get the revert message from a call.
	/// @param res bytes Response of the call.
	/// @return revertMessage string Revert message.
	function _getRevertMsg(bytes memory res) internal pure returns (string memory revertMessage) {
		if (res.length == 0) return "Transaction reverted silently";
		return abi.decode(res, (string));
	}
}

