pragma solidity ^0.5.2;

interface IHashedTimelock {
    function newContract(
        address recipient,
        address tokenContract,
        uint amount,
        bytes32 hashlock,
        uint timelock,
        bytes32 data
    ) external returns (bytes32);

    function withdraw(bytes32 contractId, bytes32 preimage) external returns (bool);

    function refund(bytes32 contractId) external returns (bool);
}

