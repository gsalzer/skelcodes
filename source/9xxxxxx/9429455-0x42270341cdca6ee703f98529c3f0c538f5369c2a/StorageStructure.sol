pragma solidity 0.6.2;

/// @title Storage Structure for CertiÐApp Certificate Contract
/// @dev This contract is intended to be inherited in Proxy and Implementation contracts.
contract StorageStructure {
  enum AuthorityStatus { NotAuthorised, Authorised, Migrated, Suspended }

  struct Certificate {
    bytes data;
    bytes signers;
  }

  struct CertifyingAuthority {
    bytes data;
    AuthorityStatus status;
  }

  mapping(bytes32 => Certificate) public certificates;
  mapping(address => CertifyingAuthority) public certifyingAuthorities;
  mapping(bytes32 => bytes32) extraData;

  address public manager;

  bytes constant public PERSONAL_PREFIX = "\x19Ethereum Signed Message:\n";

  event ManagerUpdated(
    address _newManager
  );

  event Certified(
    bytes32 indexed _certificateHash,
    address indexed _certifyingAuthority
  );

  event AuthorityStatusUpdated(
    address indexed _certifyingAuthority,
    AuthorityStatus _newStatus
  );

  event AuthorityMigrated(
    address indexed _oldAddress,
    address indexed _newAddress
  );

  modifier onlyManager() {
    require(msg.sender == manager, 'only manager can call');
    _;
  }

  modifier onlyAuthorisedCertifier() {
    require(
      certifyingAuthorities[msg.sender].status == AuthorityStatus.Authorised
      , 'only authorised certifier can call'
    );
    _;
  }
}

