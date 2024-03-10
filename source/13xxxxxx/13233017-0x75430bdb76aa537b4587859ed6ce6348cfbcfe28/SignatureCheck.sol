// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "./ECDSA.sol";
import "./Ownable.sol";

contract SignatureCheck is Ownable {
    using ECDSA for bytes32;
    address signerAddress;
    mapping(bytes => bool) signatures;

    constructor(address _signerAddress) Ownable() {
        signerAddress = _signerAddress;
    }

    function activateAccount(
        address transactor,
        bytes12 _account,
        uint256 _timestamp,
        bytes memory _signature
    ) public onlyOwner returns (bool) {
        require(signatures[_signature] == false);
        require(
            signerAddress ==
                verifySig(abi.encode(transactor, _account,_timestamp), _signature)
        );
        signatures[_signature] = true;
        return true;
    }

    function addRecipient(
        address transactor,
        bytes12 _account,
        uint256 _recipientOBFC,
        uint256 _timestamp,
        bytes memory _signature
    ) public onlyOwner returns (bool) {
        require(signatures[_signature] == false);
        require(
            signerAddress ==
                verifySig(
                    abi.encode(transactor, _account, _recipientOBFC, _timestamp),
                    _signature
                )
        );
        signatures[_signature] = true;
        return true;
    }

    function verifySig(bytes memory _params, bytes memory _signature)
        public
        pure
        returns (address)
    {
        return keccak256(_params).toEthSignedMessageHash().recover(_signature);
    }

    function setSignerAddress(address _signerAddress)
        public
        onlyOwner
        returns (bool)
    {
        signerAddress = _signerAddress;
        return true;
    }
}

