// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

abstract contract ITokenPool {
    function token() external virtual view returns (IERC20);
    function balance() external virtual view returns (uint256);
    function transfer(address to, uint256 value) external virtual returns (bool);
    function rescueFunds(address tokenToRescue, address to, uint256 amount) external virtual returns (bool);
}

