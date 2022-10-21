pragma solidity >=0.5.0 <0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";

contract Covenant is Ownable {

  using SafeMath for uint256;

  event NewSignatureAdded(uint sigId, string sigName, bool sigIsRV);
  event SignatureDeleted(uint sigId, string sigName, bool sigIsRV);
  
  string covenantText;
  
  struct Signature {
    string sigName;
    bool sigIsRV;
  }

  Signature[] public Signatures;

  function commitCovenantText(string calldata _covenantText) external onlyOwner {
    covenantText = _covenantText;
  }

  function addSignature(string calldata _sigName, bool _sigType) external onlyOwner {
    uint sigId = Signatures.push(Signature(_sigName, _sigType)) - 1;
    emit NewSignatureAdded(sigId, _sigName, _sigType);
  }

  function upgradeSignature(string calldata _sigName) external onlyOwner {
    for (uint i = 0; i < Signatures.length; i++) {
      if (keccak256(abi.encodePacked(Signatures[i].sigName)) == keccak256(abi.encodePacked(_sigName))) {
        Signatures[i].sigIsRV = true;
      }
    }
  }
  
  function deleteSignature(string calldata _sigName) external onlyOwner {
    for (uint i = 0; i < Signatures.length; i++) {
      if (keccak256(abi.encodePacked(Signatures[i].sigName)) == keccak256(abi.encodePacked(_sigName))) {
        bool _sigType = Signatures[i].sigIsRV;
        Signatures[i] = Signatures[Signatures.length - 1];
        delete Signatures[Signatures.length - 1];
        Signatures.length--;
        emit SignatureDeleted(i, _sigName, _sigType);
      }
    }
  }

  function countRV() external view onlyOwner returns(uint) {
    uint counterRV = 0;
    for (uint i = 0; i < Signatures.length; i++) {
      if (Signatures[i].sigIsRV == true) {
        counterRV++;
      }
    }
    return counterRV;
  }

  function countNRV() external view onlyOwner returns(uint) {
    uint counterNRV = 0;
    for (uint i = 0; i < Signatures.length; i++) {
      if (Signatures[i].sigIsRV == false) {
        counterNRV++;
      }
    }
    return counterNRV;
  }
}
