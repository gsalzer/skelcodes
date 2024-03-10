// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IHandler {
    function withdraw(
        bytes32 id,
        uint256 tokenIdOrAmount,
        address contractAddress
    )
    external
    returns (
        address[] memory token,
        uint256 premium,
        uint128[] memory tokenFees,
        bytes memory data
    );

    function update(
        bytes32 id,
        uint256 tokenValue,
        address contractAddress,
        bytes calldata data
    ) external;
}

