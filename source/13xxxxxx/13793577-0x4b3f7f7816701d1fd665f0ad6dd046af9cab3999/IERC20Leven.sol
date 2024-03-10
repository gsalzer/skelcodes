// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Leven {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function airdrop(address _to, uint256 amount) external returns(bool);
    function presale(address _to, uint256 amount) external returns(bool);
    function getRemainPresalCnt() external view returns(uint256);
    function getRemainAirDropCnt() external view returns(uint256);
    function getAirdropStatus(address account) external view returns(bool);
}
