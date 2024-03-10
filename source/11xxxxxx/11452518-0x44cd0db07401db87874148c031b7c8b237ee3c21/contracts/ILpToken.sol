pragma solidity ^0.6.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ILpToken is IERC20 {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}

