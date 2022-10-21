// SPDX-License-Identifier: DOGE WORLD
pragma solidity ^0.8.0;

interface IERC20
{
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function nonces(address _owner) external view returns (uint256);

    function approve(address _spender, uint256 _amount) external returns (bool);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function increaseAllowance(address _spender, uint256 _toAdd) external returns (bool);
    function decreaseAllowance(address _spender, uint256 _toRemove) external returns (bool);
    function burn(uint256 _amount) external;
}
