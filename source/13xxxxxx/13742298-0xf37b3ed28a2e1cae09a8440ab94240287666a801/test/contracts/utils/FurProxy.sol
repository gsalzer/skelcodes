// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../Furballs.sol";
import "./FurLib.sol";

/// @title FurProxy
/// @author LFG Gaming LLC
/// @notice Manages a link from a sub-contract back to the master Furballs contract
/// @dev Provides permissions by means of proxy
abstract contract FurProxy {
  Furballs public furballs;

  constructor(address furballsAddress) {
    furballs = Furballs(furballsAddress);
  }

  /// @notice Allow upgrading contract links
  function setFurballs(address addr) external onlyOwner {
    furballs = Furballs(addr);
  }

  /// @notice Proxied from permissions lookup
  modifier onlyOwner() {
    require(_permissionCheck(msg.sender) >= FurLib.PERMISSION_OWNER, "OWN");
    _;
  }

  /// @notice Permission modifier for moderators (covers owner)
  modifier gameAdmin() {
    require(_permissionCheck(msg.sender) >= FurLib.PERMISSION_ADMIN, "GAME");
    _;
  }

  /// @notice Permission modifier for moderators (covers admin)
  modifier gameModerators() {
    require(_permissionCheck(msg.sender) >= FurLib.PERMISSION_MODERATOR, "MOD");
    _;
  }

  /// @notice Generalized permissions flag for a given address
  function _permissionCheck(address addr) internal view returns (uint) {
    if(addr != address(0)) {
      uint256 size;
      assembly { size := extcodesize(addr) }
      if (addr == tx.origin && size == 0) {
        return _userPermissions(addr);
      }
    }
    return _contractPermissions(addr);
  }

  /// @notice Permission lookup (for loot engine approveSender)
  function _permissions(address addr) internal view returns (uint8) {
    // User permissions will return "zero" quickly if this didn't come from a wallet.
    if (addr == address(0)) return 0;
    uint256 size;
    assembly { size := extcodesize(addr) }
    if (size != 0) return 0;

    return _userPermissions(addr);
  }

  function _contractPermissions(address addr) internal view returns (uint) {
    if (addr == address(furballs) ||
      addr == address(furballs.engine()) ||
      addr == address(furballs.furgreement()) ||
      addr == address(furballs.governance()) ||
      addr == address(furballs.fur()) ||
      addr == address(furballs.engine().zones())
    ) {
      return FurLib.PERMISSION_CONTRACT;
    }
    return 0;
  }

  function _userPermissions(address addr) internal view returns (uint8) {
    // Invalid addresses include contracts an non-wallet interactions, which have no permissions
    if (addr == address(0)) return 0;
    if (addr == furballs.owner()) return FurLib.PERMISSION_OWNER;
    if (furballs.isAdmin(addr)) return FurLib.PERMISSION_ADMIN;
    if (furballs.isModerator(addr)) return FurLib.PERMISSION_MODERATOR;
    return FurLib.PERMISSION_USER;
  }
}

