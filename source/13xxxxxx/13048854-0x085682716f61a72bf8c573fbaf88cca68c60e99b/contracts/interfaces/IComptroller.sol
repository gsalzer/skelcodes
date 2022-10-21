// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IComptroller {
    function oracle() external view returns (address);
}

