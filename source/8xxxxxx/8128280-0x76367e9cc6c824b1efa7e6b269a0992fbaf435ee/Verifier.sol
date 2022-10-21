pragma solidity ^0.5.0;

contract Verifier {
    function verifyWithdrawSignature(
        address _trader,
        bytes calldata _signature
    ) external returns (bool) {
        return true;
    }
}
