// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function increaseApproval(address _spender, uint _addedValue) external returns (bool);

    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

}


