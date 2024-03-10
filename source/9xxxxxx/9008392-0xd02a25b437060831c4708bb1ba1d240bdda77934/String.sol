pragma solidity ^0.5.0;

/**
 * @title String
 * @dev This integrates the basic functions.
 */
library String {
    /**
     * @dev determine if strings are equal
     * @param _str1 strings
     * @param _str2 strings
     * @return bool
     */
    function compareStr(string memory _str1, string memory _str2)
        internal
        pure
        returns(bool)
    {
        if(keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2))) {
            return true;
        }
        return false;
    }
}
