// SPDX-License-Identifier: MIT

/*
*
* VerifySignature Contract
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* Verify a signature generated off-chain
* To be used for helping avoid gas wars without having to whitelist addresses on contract
*
*/

pragma solidity 0.8.9;

import "./Ownable.sol";

contract VerifySignature is Ownable {

    address public verifySigner;

    constructor() {
        verifySigner = msg.sender;
    }

    function setSigner(address _newSigner) public onlyOwner {
        verifySigner = _newSigner;
    }

    function getMessageHash(
        string memory _messageOne,
        string memory _messageTwo,
        uint _numberOne,
        uint _numberTwo,
        address _address
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_messageOne, _messageTwo, _numberOne, _numberTwo, _address));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "siglngth");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }

    function verifySignature(
        string memory _messageOne,
        string memory _messageTwo,
        uint _numberOne,
        uint _numberTwo,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 _messageHash = getMessageHash(_messageOne, _messageTwo, _numberOne, _numberTwo, msg.sender);
        bytes32 _ethSignedMessageHash = getEthSignedMessageHash(_messageHash);
        return recoverSigner(_ethSignedMessageHash, signature) == verifySigner;
    }
}
