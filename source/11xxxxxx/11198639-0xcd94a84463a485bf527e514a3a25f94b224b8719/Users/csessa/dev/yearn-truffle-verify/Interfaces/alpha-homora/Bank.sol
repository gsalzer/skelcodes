// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Bank is IERC20 {
    function deposit() external payable;
    function totalETH() external view returns (uint256);
    function withdraw(uint256 share) external;
    function pendingInterest(uint256 msgValue) external view returns (uint256);
    function debtShareToVal(uint256 debtShare) external view returns (uint256);
    function debtValToShare(uint256 debtVal) external view returns (uint256);
}

