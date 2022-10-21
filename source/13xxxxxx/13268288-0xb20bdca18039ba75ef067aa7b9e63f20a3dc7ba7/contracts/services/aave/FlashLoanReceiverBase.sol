// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {IFlashLoanReceiver} from "../../interfaces/aave/IFlashLoanReceiver.sol";
import {ILendingPool} from "../../interfaces/aave/ILendingPool.sol";
import {
    ILendingPoolAddressesProvider
} from "../../interfaces/aave/ILendingPoolAddressesProvider.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
    // solhint-disable-next-line var-name-mixedcase
    ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
    // solhint-disable-next-line var-name-mixedcase
    ILendingPool public immutable override LENDING_POOL;

    constructor(ILendingPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        LENDING_POOL = ILendingPool(provider.getLendingPool());
    }
}

