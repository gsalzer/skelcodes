// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

interface IController {
    function vaults(address) external view returns (address);
    function strategies(address) external view returns (address);
    function rewards() external view returns (address);
    function want(address) external view returns (address);
    function balanceOf(address) external view returns (uint);
    function withdraw(address, uint) external;
    function earn(address, uint) external;
}

