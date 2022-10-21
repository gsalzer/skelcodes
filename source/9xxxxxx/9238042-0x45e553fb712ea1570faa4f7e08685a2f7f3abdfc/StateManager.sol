pragma solidity 0.5.12;

import "./AdminRole.sol";

contract StateManager is AdminRole {
  event WhitelistedAdded(address indexed account);
  event WhitelistedRemoved(address indexed account);

  event BlockedAdded(address indexed account);
  event BlockedRemoved(address indexed account);

  event BlacklistedAdded(address indexed account);

  enum States { None, Whitelisted, Blacklisted, Blocked }
  mapping(address => uint256) internal addressState;

  modifier notBlocked() {
    require(!isBlocked(_msgSender()), "Blocked: caller is not blocked ");
    _;
  }
  modifier notBlacklisted() {
    require(
      !isBlacklisted(_msgSender()),
      "Blacklisted: caller is not blacklisted"
    );
    _;
  }

  function isWhitelisted(address account) public view returns (bool) {
    return addressState[account] == uint256(States.Whitelisted);
  }

  function isBlocked(address account) public view returns (bool) {
    return addressState[account] == uint256(States.Blocked);
  }

  function isBlacklisted(address account) public view returns (bool) {
    return addressState[account] == uint256(States.Blacklisted);
  }

  function addWhitelisted(address account) external onlyAdmin whenNotPaused {
    require(!isWhitelisted(account), "Whitelisted: already whitelisted");
    require(!isBlocked(account), "Whitelisted: cannot add Blocked accounts");
    require(
      !isBlacklisted(account),
      "Whitelisted: cannot add Blacklisted accounts"
    );
    _addWhitelisted(account);
  }

  function addBlocked(address account) external onlyAdmin {
    require(!isBlocked(account), "Blocked: already blocked");
    require(
      !isBlacklisted(account),
      "Blocked: cannot add Blacklisted accounts"
    );
    _addBlocked(account);
  }

  function addBlacklisted(address account) external onlyAdmin {
    require(!isBlacklisted(account), "Blacklisted: already Blacklisted");
    _addBlacklisted(account);
  }

  function removeWhitelisted(address account) external onlyAdmin whenNotPaused {
    _removeWhitelisted(account);
  }

  function removeBlocked(address account) external onlyAdmin whenNotPaused {
    _removeBlocked(account);
  }

  function renounceWhitelisted() external whenNotPaused {
    _removeWhitelisted(_msgSender());
  }

  function _addWhitelisted(address account) internal {
    addressState[account] = uint256(States.Whitelisted);
    emit WhitelistedAdded(account);
  }
  function _addBlocked(address account) internal {
    addressState[account] = uint256(States.Blocked);
    emit BlockedAdded(account);
  }

  function _addBlacklisted(address account) internal {
    addressState[account] = uint256(States.Blacklisted);
    emit BlacklistedAdded(account);
  }

  function _removeWhitelisted(address account) internal {
    delete addressState[account];
    emit WhitelistedRemoved(account);
  }

  function _removeBlocked(address account) internal {
    delete addressState[account];
    emit BlockedRemoved(account);
  }

  uint256[50] private stateManagerGap;
}

