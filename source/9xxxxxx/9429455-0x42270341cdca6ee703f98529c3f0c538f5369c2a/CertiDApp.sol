pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import 'RLP.sol';
import 'StorageStructure.sol';

/// @title CertiÐApp Smart Contract
/// @author Soham Zemse from The EraSwap Team
/// @notice This contract accepts certificates signed by multiple authorised signers
contract CertiDApp is StorageStructure {
  using RLP for bytes;
  using RLP for RLP.RLPItem;

  /// @notice Sets up the CertiDApp manager address when deployed
  constructor() public {
    _changeManager(msg.sender);
  }

  /// @notice Used by present manager to change the manager wallet address
  /// @param _newManagerAddress Address of next manager wallet
  function changeManager(address _newManagerAddress) public onlyManager {
    _changeManager(_newManagerAddress);
  }

  /// @notice Used by manager to for to update KYC / verification status of Certifying Authorities
  /// @param _authorityAddress Wallet address of certifying authority
  /// @param _data RLP encoded KYC details of certifying authority
  function updateCertifyingAuthority(
    address _authorityAddress,
    bytes memory _data,
    AuthorityStatus _status
  ) public onlyManager {
    if(_data.length > 0) {
      certifyingAuthorities[_authorityAddress].data = _data;
    }

    certifyingAuthorities[_authorityAddress].status = _status;

    emit AuthorityStatusUpdated(_authorityAddress, _status);
  }

  /// @notice Used by Certifying Authorities to change their wallet (in case of theft).
  ///   Migrating prevents any new certificate registrations signed by the old wallet.
  ///   Already registered certificates would be valid.
  /// @param _newAuthorityAddress Next wallet address of the same certifying authority
  function migrateCertifyingAuthority(
    address _newAuthorityAddress
  ) public onlyAuthorisedCertifier {
    require(
      certifyingAuthorities[_newAuthorityAddress].status == AuthorityStatus.NotAuthorised
      , 'cannot migrate to an already authorised address'
    );

    certifyingAuthorities[msg.sender].status = AuthorityStatus.Migrated;
    emit AuthorityStatusUpdated(msg.sender, AuthorityStatus.Migrated);

    certifyingAuthorities[_newAuthorityAddress] = CertifyingAuthority({
      data: certifyingAuthorities[msg.sender].data,
      status: AuthorityStatus.Authorised
    });
    emit AuthorityStatusUpdated(_newAuthorityAddress, AuthorityStatus.Authorised);

    emit AuthorityMigrated(msg.sender, _newAuthorityAddress);
  }

  /// @notice Used to submit a signed certificate to smart contract for adding it to storage.
  ///   Anyone can submit the certificate, the one submitting has to pay the nominal gas fee.
  /// @param _signedCertificate RLP encoded certificate according to CertiDApp Certificate standard.
  function registerCertificate(
    bytes memory _signedCertificate
  ) public returns (
    bytes32
  ) {
    (Certificate memory _certificateObj, bytes32 _certificateHash) = parseSignedCertificate(_signedCertificate, true);

    /// @notice Signers in this transaction
    bytes memory _newSigners = _certificateObj.signers;

    /// @notice If certificate already registered then signers can be updated.
    ///   Initializing _updatedSigners with existing signers on blockchain if any.
    ///   More signers would be appended to this in next 'for' loop.
    bytes memory _updatedSigners = certificates[_certificateHash].signers;

    /// @notice Check with every the new signer if it is not already included in storage.
    ///   This is helpful when a same certificate is submitted again with more signatures,
    ///   the contract will consider only new signers in that case.
    for(uint256 i = 0; i < _newSigners.length; i += 20) {
      address _signer;
      assembly {
        _signer := mload(add(_newSigners, add(0x14, i)))
      }
      if(_checkUniqueSigner(_signer, certificates[_certificateHash].signers)) {
        _updatedSigners = abi.encodePacked(_updatedSigners, _signer);
        emit Certified(
          _certificateHash,
          _signer
        );
      }
    }

    /// @notice check whether the certificate is freshly being registered.
    ///   For new certificates, directly proceed with adding it.
    ///   For existing certificates only update the signers if there are any new.
    if(certificates[_certificateHash].signers.length > 0) {
      require(_updatedSigners.length > certificates[_certificateHash].signers.length, 'need new signers');
      certificates[_certificateHash].signers = _updatedSigners;
    } else {
      certificates[_certificateHash] = _certificateObj;
    }

    return _certificateHash;
  }

  /// @notice Used by contract to seperate signers from certificate data.
  /// @param _signedCertificate RLP encoded certificate according to CertiDApp Certificate standard.
  /// @param _allowedSignersOnly Should it consider only KYC approved signers ?
  /// @return _certificateObj Seperation of certificate data and signers (computed from signatures)
  /// @return _certificateHash Unique identifier of the certificate data
  function parseSignedCertificate(
    bytes memory _signedCertificate,
    bool _allowedSignersOnly
  ) public view returns (
    Certificate memory _certificateObj,
    bytes32 _certificateHash
  ) {
    RLP.RLPItem[] memory _certificateRLP = _signedCertificate.toRlpItem().toList();

    _certificateObj.data = _certificateRLP[0].toRlpBytes();

    _certificateHash = keccak256(abi.encodePacked(
      PERSONAL_PREFIX,
      _getBytesStr(_certificateObj.data.length),
      _certificateObj.data
    ));

    /// @notice loop through every signature and use eliptic curves cryptography to recover the
    ///   address of the wallet used for signing the certificate.
    for(uint256 i = 1; i < _certificateRLP.length; i += 1) {
      bytes memory _signature = _certificateRLP[i].toBytes();

      bytes32 _r;
      bytes32 _s;
      uint8 _v;

      assembly {
        let _pointer := add(_signature, 0x20)
        _r := mload(_pointer)
        _s := mload(add(_pointer, 0x20))
        _v := byte(0, mload(add(_pointer, 0x40)))
        if lt(_v, 27) { _v := add(_v, 27) }
      }

      require(_v == 27 || _v == 28, 'invalid recovery value');

      address _signer = ecrecover(_certificateHash, _v, _r, _s);

      require(_checkUniqueSigner(_signer, _certificateObj.signers), 'each signer should be unique');

      if(_allowedSignersOnly) {
        require(certifyingAuthorities[_signer].status == AuthorityStatus.Authorised, 'certifier not authorised');
      }

      /// @dev packing every signer address into a single bytes value
      _certificateObj.signers = abi.encodePacked(_certificateObj.signers, _signer);
    }
  }

  /// @notice Used to change the manager
  /// @param _newManagerAddress Address of next manager wallet
  function _changeManager(address _newManagerAddress) private {
    manager = _newManagerAddress;
    emit ManagerUpdated(_newManagerAddress);
  }

  /// @notice Used to check whether an address exists in packed addresses bytes
  /// @param _signer Address of the signer wallet
  /// @param _packedSigners Bytes string of addressed packed together
  /// @return boolean value which means if _signer doesnot exist in _packedSigners bytes string
  function _checkUniqueSigner(
    address _signer,
    bytes memory _packedSigners
  ) private pure returns (bool){
    if(_packedSigners.length == 0) return true;

    require(_packedSigners.length % 20 == 0, 'invalid packed signers length');

    address _tempSigner;
    /// @notice loop through every packed signer and check if signer exists in the packed signers
    for(uint256 i = 0; i < _packedSigners.length; i += 20) {
      assembly {
        _tempSigner := mload(add(_packedSigners, add(0x14, i)))
      }
      if(_tempSigner == _signer) return false;
    }

    return true;
  }

  /// @notice Used to get a number's utf8 representation
  /// @param i Integer
  /// @return utf8 representation of i
  function _getBytesStr(uint i) private pure returns (bytes memory) {
    if (i == 0) {
      return "0";
    }
    uint j = i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (i != 0) {
      bstr[k--] = byte(uint8(48 + i % 10));
      i /= 10;
    }
    return bstr;
  }
}

