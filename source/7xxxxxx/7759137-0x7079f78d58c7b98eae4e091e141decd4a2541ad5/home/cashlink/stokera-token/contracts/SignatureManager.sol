pragma solidity ^0.5.3;

contract SignatureManager {
    // If this changes, the prefix string also has to change
    uint256 private constant EXTRA_LEN = 8 + 8 + 20 + 20;
    uint256 private constant PREFIX_STRING =
        // ("\x19Ethereum Signed Message:\n%d" % (EXTRA_LEN + 32)).encode('hex')
        0x19457468657265756d205369676e6564204d6573736167653a0a3838;

    uint256 private constant EC_LEN = 32 + 32 + 1;
    uint256 private constant SIG_LEN = EXTRA_LEN + EC_LEN;

    uint256 private constant SIGNATURE_VERSION = 1;

    event NonceUsed(uint256 nonce);
    event NonceRevoked(uint256 nonce);

    enum NonceStatus {
        Unused, Used, Revoked
    }
    mapping(uint256 => NonceStatus) nonceStatus;

    struct SignatureParams {
        uint128 expiresAt;
        uint128 version;
        uint256 nonce;
        uint256 dependentNonce;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    // Adapted from
    // https://programtheblockchain.com/posts/2018/02/17/signing-and-verifying-messages-in-ethereum/
    // Also see https://github.com/OpenZeppelin/openzeppelin-solidity/blob/v1.12.0/contracts/ECRecovery.sol
    //
    // It will take a bytestring and an offset, and extracts several values
    // from the signature at the given offset of the bytestring:
    //   * expiry date: an simple timestamp after which the signature is invalid
    //   * nonce: a unique integer value used to identify the signature
    //   * r, s, v: ECDSA signature
    //
    // Format:
    //   256 bit / 32 byte   length (Solidity "bytes" prefix)
    //    64 bit /  8 byte   expiry time
    //   160 bit / 20 byte   nonce
    //   160 bit / 20 byte   dependent nonce
    //   256 bit / 32 byte   r
    //   256 bit / 32 byte   s
    //     8 bit /  1 byte   v
    function splitSignature(bytes memory sig, uint256 offset)
        internal pure returns (SignatureParams memory params)
    {
        require(offset < sig.length && sig.length - offset >= SIG_LEN);
        uint128 expiresAt;
        uint128 version;
        uint256 nonce;
        uint256 dependentNonce;
        bytes32 r;
        bytes32 s;
        uint8 v;

        uint256 ptr;

        assembly {
            // seek to requested signature, ptr now point to 32-byte *before* the
            // current signature
            ptr := add(sig, offset)

            // 8 bytes expiry time
            ptr := add(ptr, 8)
            expiresAt := and(mload(ptr), 0xffffffffffffffff)

            // 8 bytes version
            ptr := add(ptr, 8)
            version := and(mload(ptr), 0xffffffffffffffff)

            // 20 bytes nonce
            ptr := add(ptr, 20)
            nonce := and(mload(ptr), 0xffffffffffffffffffffffffffffffffffffffff)

            // 20 bytes dependent nonce
            ptr := add(ptr, 20)
            dependentNonce := and(mload(ptr), 0xffffffffffffffffffffffffffffffffffffffff)

            // 32 bytes r
            ptr := add(ptr, 32)
            r := mload(ptr)

            // 32 bytes s
            ptr := add(ptr, 32)
            s := mload(ptr)

            // 1 byte v
            ptr := add(ptr, 32)
            v := byte(0, mload(ptr))
        }

        // web3 creates signatures with v in {0,1,2,3} instead of {27,28,29,30}
        //
        // ecrecover of course expects the latter.
        if (v < 27)
            v += 27;

        params.expiresAt = expiresAt;
        params.version = version;
        params.nonce = nonce;
        params.dependentNonce = dependentNonce;
        params.r = r;
        params.s = s;
        params.v = v;
    }

    function isNonceValidImpl(uint256 nonce) internal view returns (bool) {
        return nonceStatus[nonce] == NonceStatus.Unused;
    }

    function isNonceUsedImpl(uint256 nonce) internal view returns (bool) {
        return nonceStatus[nonce] == NonceStatus.Used;
    }

    function isNonceRevokedImpl(uint256 nonce) internal view returns (bool) {
        return nonceStatus[nonce] == NonceStatus.Revoked;
    }

    function revokeNonceImpl(uint256 nonce) internal {
        require(nonceStatus[nonce] == NonceStatus.Unused, "Nonce must be unused");
        emit NonceRevoked(nonce);
        nonceStatus[nonce] = NonceStatus.Revoked;
    }

    function makePrefixedHash(bytes32 message, bytes memory sig, uint256 offset)
        internal pure
        returns (bytes32)
    {
        uint256 extraLen = EXTRA_LEN;  // copy for inline assembly code
        uint256 prefixStr = PREFIX_STRING;  // copy for inline assembly code
        uint256 len = 28 + 32 + EXTRA_LEN;
        bytes memory preimage = new bytes(len);
        uint256 dst;
        uint256 src;
        assembly {
            // because of 32-byte size header, this points to last 32-byte word
            // of destination buffer
            dst := add(preimage, len)

            // because of 32-byte size header, this points to last 32-byte word
            // of signature params
            src := add(sig, add(offset, extraLen))

            // Copy 64 bytes (at least extraLen are needed)
            mstore(dst, mload(src))
            dst := sub(dst, 32)
            src := sub(src, 32)
            mstore(dst, mload(src))

            dst := add(preimage, 60) // 32 + 28 = size prefix + message
            mstore(dst, message)

            dst := add(preimage, 28)
            // "\x19Ethereum Signed Message:\n" ...
            mstore(dst, prefixStr)

            // Fix length field
            mstore(preimage, len)
        }
        return keccak256(preimage);
    }

    struct SignatureCheckResult {
        bool valid;
        uint256 nonce;
    }

    function isValidNonce(uint256 nonce) private view returns (bool) {
        require(nonce != 0, "nonce should never be 0");
        return nonceStatus[nonce] == NonceStatus.Unused;
    }

    function isValidDependentNonce(uint256 depNonce) private view returns (bool) {
        return depNonce == 0 || nonceStatus[depNonce] == NonceStatus.Used;
    }

    function isValidExpiryTime(uint128 expiresAt) private view returns (bool) {
        return expiresAt == 0 || expiresAt >= now;
    }

    event DebugSignatureParams(uint128 expiresAt, uint128 version,
                               uint256 nonce, uint256 dependentNonce,
                               bytes32 r, bytes32 s, uint8 v, address signedBy);

    // Verifies a signature chain
    // This should never be used outside of testing or checkAndUseSignatureImpl
    function checkSignatureChain(bytes32 message,
                                 bytes memory sig,
                                 address authority,
                                 uint256 offset,
                                 uint256 end)
        internal
        view
        returns (SignatureCheckResult memory result)
    {
        require(
            offset <= sig.length &&
            end <= sig.length &&
            offset < end &&
            (end - offset) % SIG_LEN == 0);

        bytes32 currentMessage = message;

        result.valid = false;
        result.nonce = 0;

        uint256 idx = 0;
        uint256 start = offset;
        while (offset < end) {
            SignatureParams memory params = splitSignature(sig, offset);

            address signedBy = ecrecover(makePrefixedHash(currentMessage, sig, offset),
                                         params.v, params.r, params.s);
            //emit DebugSignatureParams(params.expiresAt, params.version,
                                      //params.nonce, params.dependentNonce,
                                      //params.r, params.s, params.v,
                                      //signedBy);

            if (signedBy == address(0)
                    || !isValidExpiryTime(params.expiresAt)
                    || !isValidNonce(params.nonce)
                    || !isValidDependentNonce(params.dependentNonce)
                    || params.version != SIGNATURE_VERSION)
            {
                // Early exit because of error. The caller MUST ignore the
                // partially uninitialized nonces array
                return result;
            }

            if (offset == start) {
                // Only the first nonce (for the single non-SigningAuthority
                // signature in the chain) will be consumed
                result.nonce = params.nonce;
            }

            if (signedBy == authority) {
                result.valid = true;
                require(offset + SIG_LEN == end);
                return result;
            }

            currentMessage = keccak256(abi.encode(
                "SigningAuthority", signedBy));

            offset += SIG_LEN;
            ++idx;
        }
        require(offset == end);
    }

    event DebugHeader(uint256 header, address auth, uint256 len);
    event DebugValidSignature(uint256 offset);

    function checkSignatureImpl(bytes32 message, bytes memory sig, address authority)
        internal
        view
        returns (SignatureCheckResult memory result)
    {
        uint256 offset = 0;
        while (offset < sig.length) {
            // offset < sig.length checked just now, so LHS cannot underflow
            require(sig.length - offset >= 0x20);
            uint256 header;
            assembly {
                // skip length field and seek to offset
                header := mload(add(sig, add(0x20, offset)))
            }
            address signatureAuthority = address(header >> (256 - 160));
            uint256 len = header & 0xffffffff;

            // RHS cannot overflow due to len < 2^32
            require(sig.length - offset >= 0x20 + len);

            //emit DebugHeader(header, auth, len);
            offset += 0x20;
            if (signatureAuthority == authority) {
                result = checkSignatureChain(message, sig, authority, offset, offset + len);
                if (result.valid) {
                    //emit DebugValidSignature(offset);
                    return result;
                }
            }
            offset += len;
        }
        result.valid = false;
    }

    function consumeNonce(uint256 nonce) internal {
        require(nonce != 0, "nonce should never be 0");
        require(nonceStatus[nonce] == NonceStatus.Unused, "Nonce must be unused");
        // TODO how expensive is yielding this event?
        emit NonceUsed(nonce);
        nonceStatus[nonce] = NonceStatus.Used;
    }

    // Checks a signature and marks single-use signatures as used in case
    // of successful verification.
    function tryCheckAndUseSignatureImpl(bytes32 message, bytes memory sig,
                                         address authority)
        internal
        returns (bool)
    {
        SignatureCheckResult memory result =
            checkSignatureImpl(message, sig, authority);
        if (!result.valid) {
            return false;
        }
        require(result.nonce != 0);
        consumeNonce(result.nonce);
        return true;
    }

    function checkAndUseSignatureImpl(bytes32 message, bytes memory sig, address authority)
        internal
    {
        bool success = tryCheckAndUseSignatureImpl(message, sig, authority);
        require(success, "Invalid signature");
    }


    function revokeNonceWithSignatureImpl(uint256 nonce, bytes memory sig,
                                          address authority) internal {
        bytes32 hash = keccak256(abi.encode(
            "NonceRevocation",
            address(this),
            nonce));
        checkAndUseSignatureImpl(hash, sig, authority);
        revokeNonceImpl(nonce);
    }
}

