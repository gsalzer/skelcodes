// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

contract Events {
    
    event StakeStart(
        bytes16 indexed stakeID,
        address indexed stakerAddress,
        uint256 stakeType,
        uint256 stakedAmount,
        uint256 stakesShares,
        uint256 startDay,
        uint256 lockDays
    );

    event StakeEnd(
        bytes16 indexed stakeID,
        address indexed stakerAddress,
        uint256 stakeType,
        uint256 stakedAmount,
        uint256 stakesShares,
        uint256 rewardAmount,
        uint256 closeDay,
        uint256 penaltyAmount
    );

    event InterestScraped(
        bytes16 indexed stakeID,
        address indexed stakerAddress,
        uint256 scrapeAmount,
        uint256 scrapeDay,
        uint256 currentGriseDay
    );

    event NewGlobals(
        uint256 indexed currentGriseDay,
        uint256 totalShares,
        uint256 totalStaked,
        uint256 shortTermshare,
        uint256 MediumTermshare,
        uint256 shareRate
    );
}
