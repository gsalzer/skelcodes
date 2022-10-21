// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev Named this way to avoid conflicts with `Address` from OZ.
 */
library AddressLibrary {
  using Address for address;

  function functionCallAndReturnAddress(address paymentAddressFactory, bytes memory paymentAddressCallData)
    internal
    returns (address payable result)
  {
    bytes memory returnData = paymentAddressFactory.functionCall(paymentAddressCallData);

    // Skip the length at the start of the bytes array and return the data, casted to an address
    // solhint-disable-next-line no-inline-assembly
    assembly {
      result := mload(add(returnData, 32))
    }
  }
}

