pragma solidity 0.5.12;

contract Doctrusty {

  struct Document {
      address signer; // Notary
      uint date; // Date of notarization
      bytes32 hash; // Document Hash
  }

  /**
   *  @dev Storage space used to record all documents notarized with metadata
   */
  mapping(bytes32 => Document) registry;

  /**
   *  @dev Notarize a document identified by its 32 bytes hash by recording the hash, the sender and date in the registry
   *  @dev Emit an event Notarized in case of success
   *  @param _documentHash Document hash
   */
  function notarizeDocument(bytes32 _documentHash) external returns (bool) {
    registry[_documentHash].signer = msg.sender;
    registry[_documentHash].date = now;
    registry[_documentHash].hash = _documentHash;

    emit Notarized(msg.sender, _documentHash);

    return true;
  }

  /**
   *  @dev Verify a document identified by its hash was noterized in the registry.
   *  @param _documentHash Document hash
   *  @return bool if document was noterized previsouly in the registry
   */
  function isNotarized(bytes32 _documentHash) external view returns (bool) {
    return registry[_documentHash].hash ==  _documentHash;
  }

  /**
   *  @dev Definition of the event triggered when a document is successfully notarized in the registry
   */
  event Notarized(address indexed _signer, bytes32 _documentHash);
}
