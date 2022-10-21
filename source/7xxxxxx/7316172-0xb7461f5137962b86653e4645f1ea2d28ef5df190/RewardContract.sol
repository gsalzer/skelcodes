pragma solidity 0.5.0;

contract RewardContract {
    function balanceOf(bytes32 _bladeId) public view returns (uint256 balance);
    function assignRewards(bytes32[] calldata _bladeIds, uint256[] calldata _rewards) external;
    function claimRewards(bytes32[] calldata _bladeIds, address[] calldata _wallets) external;
    function claimReward(bytes32 _bladeId, address _to) external returns (bool ok);

    event RewardClaimed(bytes32 _bladeId, address _wallet, uint256 _amount);
    event RewardAssigned(bytes32 _bladeId, uint256 _amount);
}

