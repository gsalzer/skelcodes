// SPDX-License-Identifier: MIT AND Apache-2.0

pragma solidity 0.7.6;

/**
 * Utility library of inline functions on addresses
 */
library Address {
  // Default hash for EOA accounts returned by extcodehash
  bytes32 internal constant ACCOUNT_HASH =
    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(_address)
    }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: No contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: No contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
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

