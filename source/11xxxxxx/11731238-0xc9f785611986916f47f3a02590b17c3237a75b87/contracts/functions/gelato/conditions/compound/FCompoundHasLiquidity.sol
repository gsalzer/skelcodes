// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {ICToken} from "../../../../interfaces/dapps/Compound/ICToken.sol";
import {_getCToken} from "../../../dapps/FCompound.sol";

function _cTokenHasLiquidity(address _debtToken, uint256 _debtAmt)
    view
    returns (bool)
{
    return ICToken(_getCToken(_debtToken)).getCash() > _debtAmt;
}

