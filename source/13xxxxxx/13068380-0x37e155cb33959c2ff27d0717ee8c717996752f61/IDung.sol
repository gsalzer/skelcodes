// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;

import "./IERC20.sol";

interface IDung is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

