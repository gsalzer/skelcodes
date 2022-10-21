// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {ILendingPool} from "../../interfaces/dapps/Aave/ILendingPool.sol";
import {AaveUserData} from "../../structs/SAave.sol";
import {IERC20} from "../../interfaces/dapps/IERC20.sol";
import {
    ILendingPoolAddressesProvider
} from "../../interfaces/dapps/Aave/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../../interfaces/dapps/Aave/ILendingPool.sol";
import {LENDING_POOL_ADDRESSES_PROVIDER} from "../../constants/CAave.sol";
import {_getUserData} from "../../functions/dapps/FAave.sol";
import {
    _isAaveLiquid
} from "../../functions/gelato/conditions/aave/FAaveHasLiquidity.sol";
import {
    _aavePositionWillBeSafe
} from "../../functions/gelato/conditions/aave/FAavePositionWillBeSafe.sol";

contract AaveResolver {
    function getATokenUnderlyingBalance(address _underlying)
        public
        view
        returns (uint256)
    {
        return
            IERC20(_underlying).balanceOf(
                ILendingPool(
                    ILendingPoolAddressesProvider(
                        LENDING_POOL_ADDRESSES_PROVIDER
                    )
                        .getLendingPool()
                )
                    .getReserveData(_underlying)
                    .aTokenAddress
            );
    }

    function getPosition(address _dsa)
        public
        view
        returns (AaveUserData memory)
    {
        return _getUserData(_dsa);
    }

    function hasLiquidity(address _debtToken, uint256 _debtAmt)
        public
        view
        returns (bool)
    {
        return _isAaveLiquid(_debtToken, _debtAmt);
    }

    function aavePositionWouldBeSafe(
        address _dsa,
        uint256 _colAmt,
        address _colToken,
        uint256 _debtAmt,
        address _oracleAggregator
    ) public view returns (bool) {
        return
            _aavePositionWillBeSafe(
                _dsa,
                _colAmt,
                _colToken,
                _debtAmt,
                _oracleAggregator
            );
    }
}

