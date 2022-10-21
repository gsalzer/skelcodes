// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@yield-protocol/utils/contracts/interfaces/IERC2612.sol";


interface IUSDC is IERC20, IERC2612 { 
    function PERMIT_TYPEHASH() external view returns(bytes32);
    function DOMAIN_SEPARATOR() external view returns(bytes32);
}

