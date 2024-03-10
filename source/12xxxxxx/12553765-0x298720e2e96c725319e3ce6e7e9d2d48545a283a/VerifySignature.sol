// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ECDSA.sol";

library VerifySignature {
    function getMessageHash(
        address _from, address _to, uint128 _context, uint256 _amount, uint256 _amount2
    )
        internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_from, _to, _context, _amount, _amount2));
    }
    
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ECDSA.recover(_ethSignedMessageHash, v, r, s);
    }
    
    function splitSignature(bytes memory sig)
        internal pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function hexStrToBytes(string memory _hexStr) internal pure returns (bytes memory)
    {
        //Check hex string is valid
        if (bytes(_hexStr)[0] != '0' ||
        bytes(_hexStr)[1] != 'x' ||
        bytes(_hexStr).length % 2 != 0 ||
        bytes(_hexStr).length < 4)
        {
            revert("hexStrToBytes: invalid input");
        }

        bytes memory bytes_array = new bytes((bytes(_hexStr).length - 2) / 2);

        for (uint i = 2; i < bytes(_hexStr).length; i += 2)
        {
            uint8 tetrad1 = 16;
            uint8 tetrad2 = 16;

            //left digit
            if (uint8(bytes(_hexStr)[i]) >= 48 && uint8(bytes(_hexStr)[i]) <= 57)
                tetrad1 = uint8(bytes(_hexStr)[i]) - 48;

            //right digit
            if (uint8(bytes(_hexStr)[i + 1]) >= 48 && uint8(bytes(_hexStr)[i + 1]) <= 57)
                tetrad2 = uint8(bytes(_hexStr)[i + 1]) - 48;

            //left A->F
            if (uint8(bytes(_hexStr)[i]) >= 65 && uint8(bytes(_hexStr)[i]) <= 70)
                tetrad1 = uint8(bytes(_hexStr)[i]) - 65 + 10;

            //right A->F
            if (uint8(bytes(_hexStr)[i + 1]) >= 65 && uint8(bytes(_hexStr)[i + 1]) <= 70)
                tetrad2 = uint8(bytes(_hexStr)[i + 1]) - 65 + 10;

            //left a->f
            if (uint8(bytes(_hexStr)[i]) >= 97 && uint8(bytes(_hexStr)[i]) <= 102)
                tetrad1 = uint8(bytes(_hexStr)[i]) - 97 + 10;

            //right a->f
            if (uint8(bytes(_hexStr)[i + 1]) >= 97 && uint8(bytes(_hexStr)[i + 1]) <= 102)
                tetrad2 = uint8(bytes(_hexStr)[i + 1]) - 97 + 10;

            //Check all symbols are allowed
            if (tetrad1 == 16 || tetrad2 == 16)
                revert("hexStrToBytes: invalid input");

            bytes_array[i / 2 - 1] = bytes1(uint8(16 * tetrad1 + tetrad2));
        }

        return bytes_array;
    }
    
    function verify(
        address _signer,
        address _from,
        address _to,
        uint128 _context,
        uint256 _amount,
        uint256 _amount2,
        string memory textSignature
    )
        internal pure returns (bool)
    {
        bytes32 messageHash = getMessageHash(_from, _to, _context, _amount, _amount2);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        bytes memory signature = hexStrToBytes(textSignature);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
}
