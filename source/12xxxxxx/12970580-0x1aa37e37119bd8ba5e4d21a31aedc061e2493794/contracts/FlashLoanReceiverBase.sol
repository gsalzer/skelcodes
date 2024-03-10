// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "@aave/protocol-v2/contracts/flashloan/interfaces/IFlashLoanReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ILendingPoolAddressesProvider public MY_ADDRESSES_PROVIDER;
  ILendingPool public  MY_LENDING_POOL;

  constructor(ILendingPoolAddressesProvider provider) public {
    MY_ADDRESSES_PROVIDER = provider;
    MY_LENDING_POOL = ILendingPool(MY_ADDRESSES_PROVIDER.getLendingPool());
  }

  function ADDRESSES_PROVIDER() external view override returns  (ILendingPoolAddressesProvider){
    return MY_ADDRESSES_PROVIDER;
  }

  function LENDING_POOL() external view override returns  (ILendingPool){
    return MY_LENDING_POOL;
  }
}
