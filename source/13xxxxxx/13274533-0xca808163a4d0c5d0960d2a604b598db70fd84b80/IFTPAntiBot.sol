pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

interface IFTPAntiBot {                                                                          // Here we create the interface to interact with AntiBot
    function scanAddress(address _address, address _safeAddress, address _origin) external returns (bool);
    function registerBlock(address _recipient, address _sender) external;
}
