// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IBaseTokenData.sol";
import "./IERC20.sol";

interface IERC20Data is IBaseTokenData, IERC20 {
    function decimals() external view returns (uint256);
}
