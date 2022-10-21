pragma solidity ^0.5.16;

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function getCallAddress() external view returns (address);
    function allowance(address owner, address spender) external view returns (uint256);
}

