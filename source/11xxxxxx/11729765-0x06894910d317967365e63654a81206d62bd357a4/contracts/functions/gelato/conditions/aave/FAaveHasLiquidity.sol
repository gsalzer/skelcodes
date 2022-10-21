// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {IERC20} from "../../../../interfaces/dapps/IERC20.sol";
import {
    ILendingPoolAddressesProvider
} from "../../../../interfaces/dapps/Aave/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../../../../interfaces/dapps/Aave/ILendingPool.sol";
import {LENDING_POOL_ADDRESSES_PROVIDER} from "../../../../constants/CAave.sol";
import {
    _getRealisedDebt
} from "../../../../functions/gelato/FGelatoDebtBridge.sol";
import {_getMakerVaultDebt} from "../../../../functions/dapps/FMaker.sol";

function _isAaveLiquid(address _debtToken, uint256 _debtAmt)
    view
    returns (bool)
{
    return
        IERC20(_debtToken).balanceOf(
            ILendingPool(
                ILendingPoolAddressesProvider(LENDING_POOL_ADDRESSES_PROVIDER)
                    .getLendingPool()
            )
                .getReserveData(_debtToken)
                .aTokenAddress
        ) > _debtAmt;
}

