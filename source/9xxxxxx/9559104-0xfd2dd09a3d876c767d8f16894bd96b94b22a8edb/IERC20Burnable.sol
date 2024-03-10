pragma solidity ^0.4.24;

interface IERC20Burnable {
    function burn(address[] _receiver, uint256[] _value, uint256[] _timestamp) external;
    function burnAll(address[] _receiver) external;
}
