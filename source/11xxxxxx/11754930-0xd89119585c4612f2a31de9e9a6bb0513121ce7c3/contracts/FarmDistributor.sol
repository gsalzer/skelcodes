//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";

import "./interfaces/IFarmDistributor.sol";

contract FarmDistributor is IFarmDistributor {
    using SafeMath for uint256;

    IERC20 public rewardToken;

    constructor(IERC20 _rewardToken) public {
        rewardToken = _rewardToken;
    }

    function distribute(address farm) external override {
        uint256 amount = rewardToken.balanceOf(address(this));
        if (amount == 0) { return; }
        rewardToken.transfer(farm, amount);
    }
}

