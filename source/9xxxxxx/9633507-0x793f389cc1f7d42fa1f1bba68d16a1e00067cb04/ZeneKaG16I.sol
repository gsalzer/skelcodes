pragma solidity ^0.6.3;

abstract contract ZeneKaG16I {
    function registerG16(
        bytes32[2] memory,
        bytes32[2][2] memory,
        bytes32[2][2] memory,
        bytes32[2][2] memory,
        uint256,
        bytes32[2][] memory
    ) public virtual returns (bool);
    function commitG16(bytes32, bytes32)
        public
        virtual
        returns (bool didCommit);
    function proveG16(
        bytes32,
        uint256[2] memory,
        uint256[2][2] memory,
        uint256[2] memory,
        uint256[] memory
    ) public virtual returns (bool);
    function prover(bytes32) public virtual returns (address);
    function commitBlock(bytes32) public view virtual returns (uint256);
    function verify(bytes32, address) public view virtual returns (bool);
    function input(bytes32, address)
        public
        view
        virtual
        returns (uint256[] memory);
}

