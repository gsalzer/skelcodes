// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./BoringERC20.sol";

interface IMasterChefV2 {
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function set(uint256 _pid, uint256 _allocPoint, address _rewarder, bool overwrite) external;
    function add(uint256 allocPoint, address _lpToken, address _rewarder) external;
    function harvestFromMasterChef() external;
    function sushiPerBlock() external view returns (uint256);
    function owner() external view returns (address);
    function totalAllocPoint() external view returns (uint256);
    function lpToken(uint256) external view returns (IERC20);
}

