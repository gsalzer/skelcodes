// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWolfPack {

    function getTokenMinter(uint256 _tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function getSupply() external view returns (uint256);
    
}
