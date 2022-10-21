// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

interface IOracle {
    function withdrawable() external view returns (uint256);

    function withdraw(address _recipient, uint256 _amount) external;

    function transferOwnership(address _newOwner) external;
}

