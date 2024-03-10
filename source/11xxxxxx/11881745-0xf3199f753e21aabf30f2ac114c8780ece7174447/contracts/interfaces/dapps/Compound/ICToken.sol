// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ICToken {
    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getCash() external view returns (uint256);
}

