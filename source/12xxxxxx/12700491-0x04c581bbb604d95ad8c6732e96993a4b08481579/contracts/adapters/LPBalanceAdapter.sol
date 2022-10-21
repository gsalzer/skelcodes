// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";

contract LPBalanceAdapter {
    address public pair;

    constructor(address _pair) {
        pair = _pair;
    }

    function getBalance(address token, address account)
        public
        view
        returns (uint256)
    {
        uint256 balance = (IERC20(token).balanceOf(pair) *
            IERC20(pair).balanceOf(account)) / IERC20(pair).totalSupply();
        return balance;
    }
}

