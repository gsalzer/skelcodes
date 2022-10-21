pragma solidity ^0.4.18;
// from
// https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol


library BytesLib {
  function toAddress(bytes _bytes, uint _start) internal pure returns (address) {
    require(_bytes.length >= (_start + 20));
    address tempAddress;

    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
    }

    return tempAddress;
  }

  function toUint(bytes _bytes, uint _start) internal pure returns (uint256) {
    require(_bytes.length >= (_start + 32));
    uint256 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x20), _start))
    }

    return tempUint;
  }
}

