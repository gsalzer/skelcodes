pragma solidity ^0.5.0;

contract ZeneKaG16I {
    function registerG16(
        bytes32[2] memory,
        bytes32[2][2] memory,
        bytes32[2][2] memory,
        bytes32[2][2] memory,
        uint256,
        bytes32[2][] memory
    ) public returns (bool);
    function commitG16(bytes32, bytes32) public returns (bool didCommit);
    function proveG16(
        bytes32,
        uint256[2] memory,
        uint256[2][2] memory,
        uint256[2] memory,
        uint256[] memory
    ) public returns (bool);
    function verify(bytes32, address) public view returns (bool);
    function input(bytes32, address) public view returns (uint256[] memory);
}

