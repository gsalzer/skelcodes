// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../utils/Governable.sol';
import '../utils/CollectableDust.sol';
import '../utils/Pausable.sol';

abstract
contract UtilsReady is Governable, CollectableDust, Pausable {

  constructor() public Governable(msg.sender) {
  }

  // Governable: restricted-access
  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external override onlyPendingGovernor {
    _acceptGovernor();
  }

  // Collectable Dust: restricted-access
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override virtual onlyGovernor {
    _sendDust(_to, _token, _amount);
  }

  // Pausable: restricted-access
  function pause(bool _paused) external override onlyGovernor {
    _pause(_paused);
  }

}

