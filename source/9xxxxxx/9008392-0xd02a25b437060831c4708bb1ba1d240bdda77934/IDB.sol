pragma solidity ^0.5.0;

/**
 * @title DB interface
 * @dev This Provide database support services interface
 */
contract IDB {
    function registerUser(address addr, string memory code, string memory rCode) public;
    function setUser(address addr, uint status) public;
    function isUsedCode(string memory code) public view returns (bool);
    function getCodeMapping(string memory code) public view returns (address);
    function getIndexMapping(uint uid) public view returns (address);
    function getUserInfo(address addr) public view returns (uint[2] memory info, string memory code, string memory rCode);
    function getCurrentUserID() public view returns (uint);
    function getRCodeMappingLength(string memory rCode) public view returns (uint);
    function getRCodeMapping(string memory rCode, uint index) public view returns (string memory);
}
