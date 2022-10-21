// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IStakeCoinageFactory {
    function deploy(address owner) external returns (address);
}

