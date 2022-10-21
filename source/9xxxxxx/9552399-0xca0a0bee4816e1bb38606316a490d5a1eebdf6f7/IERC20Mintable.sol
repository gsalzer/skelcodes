pragma solidity ^0.4.24;

interface IERC20Mintable {
    function mint(address[] _receiver, uint256[] _value, uint256[] _timestamp) external;
}
