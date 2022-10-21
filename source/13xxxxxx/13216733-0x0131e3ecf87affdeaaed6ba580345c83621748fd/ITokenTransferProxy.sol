// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.4;

interface ITokenTransferProxy {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;

    function freeReduxTokens(address user, uint256 tokensToFree) external;
}

