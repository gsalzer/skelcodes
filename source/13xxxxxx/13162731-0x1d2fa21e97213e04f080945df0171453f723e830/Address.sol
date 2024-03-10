// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;


/**
 * Utility library of inline functions on addresses
 */
library Address {
  

	/**
	* @dev Returns true if `account` is a contract.
	*
	* [IMPORTANT]
	* ====
	* It is unsafe to assume that an address for which this function returns
	* false is an externally-owned account (EOA) and not a contract.
	*
	* Among others, `isContract` will return false for the following
	* types of addresses:
	*
	*  - an externally-owned account
	*  - a contract in construction
	*  - an address where a contract will be created
	*  - an address where a contract lived, but was destroyed
	* ====
	*/
	function isContract(address account) internal view returns (bool) {
	// This method relies on extcodesize, which returns 0 for contracts in
	// construction, since the code is only stored at the end of the
	// constructor execution.

	uint256 size;
	// solhint-disable-next-line no-inline-assembly
	assembly { size := extcodesize(account) }
	return size > 0;
	}

	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	}

	/**
		* @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
		* `errorMessage` as a fallback revert reason when `target` reverts.
		*
		* _Available since v3.1._
		*/
	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	/**
		* @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
		* but also transferring `value` wei to `target`.
		*
		* Requirements:
		*
		* - the calling contract must have an ETH balance of at least `value`.
		* - the called Solidity function must be `payable`.
		*
		* _Available since v3.1._
		*/
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}


	/**
		* @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
		* with `errorMessage` as a fallback revert reason when `target` reverts.
		*
		* _Available since v3.1._
		*/
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{value: value}(data);
		return verifyCallResult(success, returndata, errorMessage);
	}


	/**
		* @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
		* revert reason using the provided one.
		*
		* _Available since v4.3._
		*/
	function verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) internal pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			// Look for revert reason and bubble it up if present
			if (returndata.length > 0) {
				// The easiest way to bubble the revert reason is using memory via assembly

				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}
