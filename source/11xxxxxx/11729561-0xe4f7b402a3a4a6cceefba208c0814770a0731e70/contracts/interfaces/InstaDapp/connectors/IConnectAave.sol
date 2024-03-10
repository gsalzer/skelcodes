// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IConnectAave {
    function borrow(
        address token,
        uint256 amt,
        uint256 _rateMode,
        uint256 getId,
        uint256 setId
    ) external payable;

    function deposit(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable;
}

