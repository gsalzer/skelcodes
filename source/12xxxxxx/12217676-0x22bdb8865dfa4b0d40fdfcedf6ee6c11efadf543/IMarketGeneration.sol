// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

interface IMarketGeneration
{
    function totalContributionPerRound(uint8 round) external view returns (uint256);
    function referralPoints(address) external view returns (uint256);
    function totalContribution(address) external view returns (uint256);
    function contributionPerRound(address, uint8) external view returns (uint256);
    function totalReferralPoints() external view returns (uint256);
    function buyRoundsCount() external view returns (uint8);
}
