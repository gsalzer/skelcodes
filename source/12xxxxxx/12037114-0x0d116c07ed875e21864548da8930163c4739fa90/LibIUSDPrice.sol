// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

interface IUSDPrice {
    function etherPrice() external view returns (uint256);
    function vokenPrice() external view returns (uint256);
}

