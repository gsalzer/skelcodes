pragma solidity ^0.5.7;

import "./IERC20.sol";
import "./Constants.sol";
import "./IAllowanceChecker.sol";


contract AllowanceChecker is Constants {

    modifier requireAllowance(
        address _coinAddress,
        address _coinHolder,
        uint256 _expectedBalance
    ) {
        require(
            getCoinAllowance(
                _coinAddress,
                _coinHolder
            ) >= _expectedBalance,
            ERROR_BALANCE_IS_NOT_ALLOWED
        );
        _;
    }

    function getCoinAllowance(
        address _coinAddress,
        address _coinHolder
    )
    internal
    view
    returns (uint256)
    {
        return IERC20(_coinAddress).allowance(
            _coinHolder,
            address(this)
        );
    }
}

