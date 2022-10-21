pragma solidity ^0.5.2;

import "./Ownable.sol";

contract Adminable is Ownable {
    mapping (address => bool) public admins;

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "not admin");
        _;
    }

    function setAdmin(address user, bool value) external onlyOwner {
        admins[user] = value;
    }

    function isAdmin(address user) internal view returns (bool) {
      return admins[user] || isOwner();
    }
}

