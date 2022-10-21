pragma solidity 0.4.24;

library Utils {
    
    // convert a string less than 32 characters long to bytes32
    function toBytes16(string _string) pure internal returns (bytes16) {
        // make sure that the string isn't too long for this function
        // will work but will cut off the any characters past the 32nd character
        bytes16 _stringBytes;
        string memory str = _string;
    
        // simplest way to convert 32 character long string
        assembly {
          // load the memory pointer of string with an offset of 32
          // 32 passes over non-core data parts of string such as length of text
          _stringBytes := mload(add(str, 32))
        }
        return _stringBytes;
    }

    
    
}
