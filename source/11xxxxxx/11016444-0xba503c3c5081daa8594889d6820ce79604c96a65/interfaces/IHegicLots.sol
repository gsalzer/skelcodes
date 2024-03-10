// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

interface IHegicLots is IERC20 {
    function buyLot() external view returns (bool);
}

