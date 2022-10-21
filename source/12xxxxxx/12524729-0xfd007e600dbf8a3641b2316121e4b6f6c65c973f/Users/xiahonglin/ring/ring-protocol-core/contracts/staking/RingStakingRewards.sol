// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../external/StakingRewardsV2.sol";

/// @title A StakingRewards contract for earning RING with staked RUSD/RING LP tokens
/// @author Ring Protocol
/// @notice deposited LP tokens will earn RING over time at a linearly decreasing rate
contract RingStakingRewards is StakingRewardsV2 {
    constructor(
        address _distributor,
        address _ring,
        address _rusd,
        uint256 _duration
    ) 
        StakingRewardsV2(_distributor, _ring, _rusd, _duration)
    {}
}

