pragma solidity >=0.4.23 <0.8.0;
// SPDX-License-Identifier: MIT

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

