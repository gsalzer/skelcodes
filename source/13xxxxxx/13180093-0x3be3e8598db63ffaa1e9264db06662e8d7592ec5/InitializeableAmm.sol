// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./ISeriesController.sol";

interface InitializeableAmm {
    function initialize(
        ISeriesController _seriesController,
        address _priceOracle,
        IERC20 _underlyingToken,
        IERC20 _priceToken,
        IERC20 _collateralToken,
        address _tokenImplementation,
        uint16 _tradeFeeBasisPoints
    ) external;
}

