pragma solidity ^0.5.8;

contract KeyCup  {
  function generateQR(string memory salt) public view returns (bytes32 hash) {
    hash = keccak256(abi.encodePacked(address(this),msg.sender, salt));
  }
  function hashQRCode(bytes32 qr, uint256 pin) public pure returns (bytes32 hash) {
    hash = keccak256(abi.encodePacked(qr, pin));
  }
}
