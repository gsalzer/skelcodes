pragma solidity ^0.5.0;

import "./SafeMath.sol";

library VestingPlan{
    using SafeMath for uint256;

    struct AccountTimePlan {
        uint256 amount;
        uint256 timestamp;
    }
    
    struct AccountPlans{
        mapping(address => AccountTimePlan[])  _account_plans;
        address[]  _accounts;
        mapping(address=> uint256)  _account_released;
    }
}

