pragma solidity ^0.6.2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IFarming {
    function createPool(IERC20, uint256) external;

    function updateRewardsPerPool() external;

    function countPools() external view returns (uint256);
}

