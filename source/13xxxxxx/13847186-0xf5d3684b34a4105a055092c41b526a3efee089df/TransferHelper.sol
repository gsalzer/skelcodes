// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "IWETH.sol";
import "IERC20.sol";
import "SafeERC20.sol";

contract TransferHelper {

  using SafeERC20 for IERC20;

  // Mainnet
  IWETH internal constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  // Goerli
  // IWETH internal constant WETH = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

  function _safeTransferFrom(address _token, address _sender, uint _amount) internal {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    IERC20(_token).safeTransferFrom(_sender, address(this), _amount);
  }

  function _safeTransfer(address _token, address _recipient, uint _amount) internal {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    IERC20(_token).safeTransfer(_recipient, _amount);
  }

  function _wethWithdrawTo(address _to, uint _amount) internal {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    require(_to != address(0), "TransferHelper: invalid recipient");

    WETH.withdraw(_amount);
    (bool success, ) = _to.call { value: _amount }(new bytes(0));
    require(success, 'TransferHelper: ETH transfer failed');
  }

  function _depositWeth() internal {
    require(msg.value > 0, "TransferHelper: amount must be > 0");
    WETH.deposit { value: msg.value }();
  }
}

