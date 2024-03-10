pragma solidity ^0.5.10;

/**
  * @title contract for generating HEX pointer
  * for functions.
  *
  * @dev this contract is a tool meant to be used
  * on local JavaScript VM.
  *
  */
contract callbackSelector {

    /**
      * @notice function which returns function HEX pointer (callbackSelector)
      *
      * @param _function function name with parameter types. Case and whitespace sensitive.
      *
      * @dev example: `function get(string memory _function)`
      *    _function: `get(string)`
      *       result: `0x693ec85e`
      */
    function get(string memory _function) public pure returns (bytes4) {
        return bytes4(keccak256(abi.encodePacked(_function)));
    }
}
