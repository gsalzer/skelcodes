pragma solidity 0.5.16;

interface IStakingRewards {
    // Mutative
    function stake(uint256 amount) external;

    function unstakeAndClaimRewards(uint256 unstakeAmount) external;

    function unstake(uint256 amount) external;

    function claimRewards() external;

    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken(uint256 rewardTokenIndex) external view returns (uint256);

    function earned(address account, uint256 rewardTokenIndex) external view returns (uint256);

    function getRewardForDuration(uint256 rewardTokenIndex) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

