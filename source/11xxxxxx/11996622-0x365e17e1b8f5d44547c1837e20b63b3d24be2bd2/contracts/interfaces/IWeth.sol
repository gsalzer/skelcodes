pragma solidity 0.6.6;

import "@kyber.network/utils-sc/contracts/IERC20Ext.sol";


interface IWeth is IERC20Ext {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

