// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

library String {
  // From https://ethereum.stackexchange.com/questions/10811/solidity-concatenate-uint-into-a-string

  function appendUintToString(string memory inStr, uint v) internal pure returns (string memory str) {
    uint maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint i = 0;
    while (v != 0) {
      uint remainder = v % 10;
      v = v / 10;
      reversed[i++] = bytes1(uint8(48 + remainder));
    }
    bytes memory inStrb = bytes(inStr);
    bytes memory s = new bytes(inStrb.length + i);
    uint j;
    for (j = 0; j < inStrb.length; j++) {
      s[j] = inStrb[j];
    }
    for (j = 0; j < i; j++) {
      s[j + inStrb.length] = reversed[i - 1 - j];
    }
    str = string(s);
  }
}

