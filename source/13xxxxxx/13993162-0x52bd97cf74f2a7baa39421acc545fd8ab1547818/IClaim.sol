// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClaim {

    function claim(uint256 _punkIndex) external returns(bool);
}

