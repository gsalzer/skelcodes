// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    _cTokenHasLiquidity
} from "../../functions/gelato/conditions/compound/FCompoundHasLiquidity.sol";
import {
    _compoundPositionWillBeSafe
} from "../../functions/gelato/conditions/compound/FCompoundPositionWillBeSafe.sol";
import {ICToken} from "../../interfaces/dapps/Compound/ICToken.sol";
import {_getCToken} from "../../functions/dapps/FCompound.sol";

contract CompoundResolver {
    function compoundHasLiquidity(uint256 _amountToBorrow, address _debtToken)
        public
        view
        returns (bool)
    {
        return _cTokenHasLiquidity(_debtToken, _amountToBorrow);
    }

    function cTokenBalance(address _token) public view returns (uint256) {
        return ICToken(_getCToken(_token)).getCash();
    }

    function compoundPositionWouldBeSafe(
        address _dsa,
        uint256 _colAmt,
        address _debtToken,
        uint256 _debtAmt
    ) public view returns (bool) {
        return _compoundPositionWillBeSafe(_dsa, _colAmt, _debtToken, _debtAmt);
    }
}

