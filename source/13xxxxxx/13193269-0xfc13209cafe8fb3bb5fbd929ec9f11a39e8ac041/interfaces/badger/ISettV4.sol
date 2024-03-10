// SPDX-License-Identifier: MIT

pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

interface ISettV4 {
    function deposit(uint256 _amount) external;

    function depositFor(address _recipient, uint256 _amount) external;


    function withdraw(uint256 _amount) external;

    function getPricePerFullShare() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);
}

