pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT License

interface FTPAntiBot {
    function scanAddress(address _recipient, address _sender, address _origin) external returns (bool);
    function registerBlock(address _recipient, address _sender, address _origin) external;
}

