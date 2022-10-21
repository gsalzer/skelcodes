// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./IEIP2612.sol";

interface IEIP2612Detail is IEIP2612 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory); 
    function decimals() external view returns (uint8); 
}
