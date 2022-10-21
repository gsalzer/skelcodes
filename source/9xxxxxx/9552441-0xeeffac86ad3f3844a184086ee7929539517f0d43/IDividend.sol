pragma solidity ^0.4.24;

interface IDividend {
    function transferFrom(address erc20Token, address from, address[] investors, uint[] amount) external;
}
