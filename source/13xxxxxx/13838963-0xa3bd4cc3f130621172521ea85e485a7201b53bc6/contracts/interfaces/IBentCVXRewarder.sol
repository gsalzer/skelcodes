// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IBentCVXRewarder {
    function deposit(address _user, uint256 _amount) external;

    function withdraw(address _user, uint256 _amount) external;

    function claimAll(address _user) external returns (bool claimed);

    function claim(address _user, uint256[] memory pids)
        external
        returns (bool claimed);
}

