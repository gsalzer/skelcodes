// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

import "../lib/SafeMath.sol";
import "../lib/BytesLib.sol";

contract MetaTxUtils {
	using SafeMath for uint256;
	using BytesLib for bytes;

	/// @dev Get the chain ID constant.
	/// @return chainId The chain id.
	function getChainId() public pure returns (uint256 chainId) {
		assembly {
			chainId := chainid()
		}
		return chainId;
	}

	/// @notice Execute a transaction.
	/// @param to address Address of the target.
	/// @param value uint256 Amount of wei to send.
	/// @param gasLimit uint256 Amount of gas to send.
	/// @param data bytes Encoded calldata.
	/// @return returnData bytes Response of the call.
	function _executeTransaction(
		address to,
		uint256 value,
		uint256 gasLimit,
		bytes memory data
	) internal returns (bytes memory returnData) {
		// perform external call
		(bool success, bytes memory res) = to.call{gas: gasLimit, value: value}(data);
		// Get the revert message of the call and revert with it if the call failed
		if (!success) {
			string memory revertMsg = _getRevertMsg(res);
			revert(revertMsg);
		}
		// return results
		return res;
	}

	/// @dev Decode transaction data.
	/// @param transaction Transaction (to, value, gasLimit, data).
	/// @return to address Address of the target.
	/// @return value uint256 Amount of wei to send.
	/// @return gasLimit uint256 Amount of gas to send.
	/// @return nonce uint256 Unique tx salt.
	/// @return data bytes Encoded calldata.
	function _decodeTransaction(bytes memory transaction)
		internal
		pure
		returns (
			address to,
			uint256 value,
			uint256 gasLimit,
			uint256 nonce,
			bytes memory data
		)
	{
		return abi.decode(transaction, (address, uint256, uint256, uint256, bytes));
	}

	/// @notice Get the revert message from a call.
	/// @param res bytes Response of the call.
	/// @return revertMessage string Revert message.
	function _getRevertMsg(bytes memory res) internal pure returns (string memory revertMessage) {
		// If the _res length is less than 68, then the transaction failed silently (without a revert message)
		if (res.length < 68) return "Transaction reverted silently";
		bytes memory revertData = res.slice(4, res.length - 4); // Remove the selector which is the first 4 bytes
		return abi.decode(revertData, (string)); // All that remains is the revert string
	}
}

