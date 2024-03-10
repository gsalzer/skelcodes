pragma solidity ^0.6.4;

/**
 * @title EIP20Interface
 * @dev EIP 20 token contract interface.
 */
interface EIP20Interface {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address usr, uint amount) external returns(bool);
    function transfer(address dst, uint256 amount) external returns(bool);
    function transferFrom(address src, address dst, uint amount) external returns(bool);
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}
