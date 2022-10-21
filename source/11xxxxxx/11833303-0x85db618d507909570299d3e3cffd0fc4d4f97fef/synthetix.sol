// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "./SafeERC20.sol";

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

interface ISynth is IERC20 {
    function transferAndSettle(address to, uint256 value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface ISynthetix is IERC20 {
    function exchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);
}

interface IExchanger {
    // Views
    function getAmountsForExchange(
        uint256 sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint256 amountReceived,
            uint256 fee,
            uint256 exchangeFeeRate
        );

    function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint256);

    // Mutative functions
    function exchange(
        address from,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress
    ) external returns (uint256 amountReceived);
}

interface DelegateApprovals {
    function approveExchangeOnBehalf(address delegate) external;
}

