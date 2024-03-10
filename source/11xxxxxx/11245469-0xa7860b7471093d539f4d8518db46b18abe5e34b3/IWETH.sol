pragma solidity ^0.7.4;
// SPDX-License-Identifier: License got rugged

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

