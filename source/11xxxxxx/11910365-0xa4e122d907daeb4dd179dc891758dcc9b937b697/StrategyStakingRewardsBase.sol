pragma solidity >=0.6.0;

import "./StrategyBase.sol";

abstract contract StrategyStakingRewardsBase is StrategyBase {
    //Old name for this variable was "rewards"
    address public stakingContract; 

    // **** Getters ****
    constructor(
        address _stakingContract,
        address _want,
        address _strategist
    )
        public
        StrategyBase(_want, _strategist)
    {
        stakingContract = _stakingContract;
    }

    //Note to self: Frax pool's balanceOf() returns sum of unlocked + locked stakes
    function balanceOfPool() public override view returns (uint256) {
        return IStakingRewards(stakingContract).balanceOf(address(this));
    }

    function getHarvestable() external override view returns (uint256) {
        return IStakingRewards(stakingContract).earned(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(stakingContract, 0);
            IERC20(want).safeApprove(stakingContract, _want);
            IStakingRewards(stakingContract).stake(_want);
        }
    }

    function depositLocked(uint256 _secs) public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(stakingContract, 0);
            IERC20(want).safeApprove(stakingContract, _want);
            IStakingRewards(stakingContract).stakeLocked(_want, _secs);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingRewards(stakingContract).withdraw(_amount);
        return _amount;
    }

    //Not all the reserves need to be available if the pool is large enough
    function _withdrawSomeLocked(bytes32 kek_id)
        internal
        override
    {
        IStakingRewards(stakingContract).withdrawLocked(kek_id);
    }
}
