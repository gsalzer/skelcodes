// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibSafeMath.sol";
import "LibBaseAuth.sol";
import "LibIERC20.sol";


contract WithUSDToken is BaseAuth {
    using SafeMath for uint256;
    
    IERC20 private _token;
    uint8 private _decimalsDiff;
    uint8 private constant DEFAULT_DECIMALS = 6;

    constructor ()
    {
        setUSDToken(address(0x6B175474E89094C44Da98b954EedeAC495271d0F), 18); // DAI Stablecoin
    }

    function setUSDToken(address tokenContract, uint8 decimals)
        public
        onlyAgent
    {
        require(decimals >= DEFAULT_DECIMALS, "Set USD Token: decimals less than 6");
        require(decimals <= 18, "Set USD Token: decimals greater than 18");

        _token = IERC20(tokenContract);
        _decimalsDiff = decimals - DEFAULT_DECIMALS;
    }

    function _getUSDBalance()
        internal
        view
        returns (uint256)
    {
        if (_decimalsDiff > 0) {
            return _token.balanceOf(address(this)).div(10 ** _decimalsDiff);
        } else {
            return _token.balanceOf(address(this));
        }
    }

    function _transferUSD(address recipient, uint256 amount)
        internal
    {
        if (_decimalsDiff > 0) {
            _token.transfer(recipient, amount.mul(10 ** _decimalsDiff));
        } else {
            _token.transfer(recipient, amount);
        }
    }
}

