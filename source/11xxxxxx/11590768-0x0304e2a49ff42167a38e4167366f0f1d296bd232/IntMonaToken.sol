// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";

interface MonaToken is IERC20 {
    
    function burn(uint256 amount) external;
}
