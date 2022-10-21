// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ISDRF is IERC20 {

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
    
}

