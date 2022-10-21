pragma solidity ^0.5.0;


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed from, address indexed to, uint256 amount);

    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

