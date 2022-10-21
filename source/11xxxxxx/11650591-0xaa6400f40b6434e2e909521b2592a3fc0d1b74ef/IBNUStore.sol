pragma solidity ^0.7.1;

/**
@title Share token sale BNU interface
 */
interface IBNUStore{
    /**
    * @dev Transfer BNU token from contract to `recipient`
    */
    function transfer(address recipient, uint amount) external returns(bool);
}

// SPDX-License-Identifier: MIT
