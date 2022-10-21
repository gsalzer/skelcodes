// File: contracts/interfaces/IWallet.sol

pragma solidity ^0.5.1;


interface IWallet {
    /**
    * @dev Verifies that a signature is valid.
    * @param _hash - Message hash that is signed.
    * @param _signature - Proof of signing.
    * @return Validity of order signature.
    */
    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    )
    external
    view
    returns (bool isValid);
}

// File: contracts/SignatureValidator.sol

pragma solidity ^0.5.1;



contract SignatureValidator {
    // Allowed signature types.
    enum SignatureType {
        Invalid,         // 0x00, default value
        EIP712,          // 0x01
        EthSign,         // 0x02
        Wallet,          // 0x03
        NSignatureTypes  // 0x04, number of signature types. Always leave at end.
    }

    function isValidSignature(
        bytes32 _hash,
        address _signerAddress,
        uint8 _signatureType,
        bytes memory _signature
    )
    public
    view
    returns (bool)
    {

        require(
            _signature.length > 0,
            "The signature length should be greather than 0"
        );

        // Ensure signature is supported
        require(
            _signatureType != uint8(SignatureType.Invalid) &&
            _signatureType < uint8(SignatureType.NSignatureTypes),
            "Signature unsopported"
        );

        SignatureType signatureType = SignatureType(_signatureType);

        bool isValid;

        // Signature using EIP712
        if (signatureType == SignatureType.EIP712) {
            isValid = _isValid712Signature(_hash, _signerAddress, _signature);

        // Signed using web3.eth_sign
        } else if (signatureType == SignatureType.EthSign) {
            isValid = _isValidPersonalSignature(_hash, _signerAddress, _signature);

        // Signature verified by wallet contract.
        } else if (signatureType == SignatureType.Wallet) {
            isValid = _isValidWalletSignature(_hash, _signerAddress, _signature);
        }

        return isValid;
    }

    function _isValid712Signature(
        bytes32 _hash,
        address _signerAddress,
        bytes memory _signature
    )
    internal
    pure
    returns (bool)
    {
        require(
            _signature.length == 65,
            "The signature length should be 65"
        );

        (uint8 v, bytes32 r, bytes32 s) = _getVRS(_signature);

        return _signerAddress == ecrecover(
            _hash,
            v,
            r,
            s
        );
    }

    function _isValidPersonalSignature(
        bytes32 _hash,
        address _signerAddress,
        bytes memory _signature
    )
    internal
    pure
    returns (bool)
    {
        require(
            _signature.length == 65,
            "The signature length should be 65"
        );

        (uint8 v, bytes32 r, bytes32 s) = _getVRS(_signature);

        return _signerAddress == ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _hash
            )),
            v,
            r,
            s
        );
    }

    function _isValidWalletSignature(
        bytes32 _hash,
        address _walletAddress,
        bytes memory _signature
    )
    internal
    view
    returns (bool)
    {
        bytes memory callData = abi.encodeWithSelector(
            IWallet(_walletAddress).isValidSignature.selector,
            _hash,
            _signature
        );

        // Static call the verification function.
        (bool didSucceed, bytes memory returnData) = _walletAddress.staticcall(callData);

        // Return data should be a single bool.
        if (didSucceed && returnData.length == 32) {
            bytes32 encodedReturnData;
            /* solium-disable-next-line */
            assembly {
                encodedReturnData := mload(add(returnData, 0x20))
            }
            return uint256(encodedReturnData) == 1;
        }

        return false;
    }

    function _getVRS(
        bytes memory _signature
    )
    internal
    pure
    returns (uint8 v, bytes32 r, bytes32 s)
    {
        /* solium-disable-next-line */
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := and(mload(add(_signature, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }
    }
}
