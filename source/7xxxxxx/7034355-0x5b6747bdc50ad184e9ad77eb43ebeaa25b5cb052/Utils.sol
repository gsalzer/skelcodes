pragma solidity ^0.5.0 <0.6.0;

contract C3Utils {
  function isContract(address x) internal view returns(bool) {
    uint256 size;
    // For now there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.

    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(x) }
    return size > 0;
  }
}
