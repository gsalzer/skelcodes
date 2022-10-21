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
    
    function verify(
        address _signer,
        address _from,
        address _to,
        uint128 _context,
        uint256 _amount,
        uint256 _amount2,
        uint8 v,
        bytes32 r, 
        bytes32 s
    )
        internal pure returns (bool)
    {
        bytes32 messageHash = getMessageHash(_from, _to, _context, _amount, _amount2);
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

        return ECDSA.recover(ethSignedMessageHash, v, r, s) == _signer;
    }
}
