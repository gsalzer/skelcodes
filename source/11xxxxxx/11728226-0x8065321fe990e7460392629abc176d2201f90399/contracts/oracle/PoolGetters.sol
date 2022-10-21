/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IDAO.sol";
import "../external/Decimal.sol";
import "./PoolState.sol";
import "../Constants.sol";

contract PoolGetters is PoolState {
    using SafeMath for uint256;

    /**
     * Global
     */

    function dai() public view returns (address) {
        return Constants.getDaiAddress();
    }

    function dao() public view returns (IDAO) {
        return _state.dao;
    }

    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }

    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }

    function totalClaimable() public view returns (uint256) {
        return _state.balance.claimable;
    }

    function totalPhantom() public view returns (uint256) {
        return _state.balance.phantom;
    }

    function totalRewarded() public view returns (uint256) {
        return rewardsToken().balanceOf(address(this)).sub(totalClaimable());
    }

    function paused() public view returns (bool) {
        return _state.paused;
    }

    /**
     * Account
     */

    function balanceOfStaged(address account) public view returns (uint256) {
        return _state.accounts[account].staged;
    }

    function balanceOfClaimable(address account) public view returns (uint256) {
        return _state.accounts[account].claimable;
    }

    function balanceOfBonded(address account) public view returns (uint256) {
        return _state.accounts[account].bonded;
    }

    function balanceOfPhantom(address account) public view returns (uint256) {
        return _state.accounts[account].phantom;
    }

    function balanceOfRewarded(address account) public view returns (uint256) {
        uint256 totalBonded = totalBonded();
        if (totalBonded == 0) {
            return 0;
        }

        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom());
        uint256 balanceOfRewardedWithPhantom = totalRewardedWithPhantom.mul(balanceOfBonded(account)).div(totalBonded);

        uint256 balanceOfPhantom = balanceOfPhantom(account);
        if (balanceOfRewardedWithPhantom > balanceOfPhantom) {
            return balanceOfRewardedWithPhantom.sub(balanceOfPhantom);
        }
        return 0;
    }

    function statusOf(address account) public view returns (PoolAccount.Status) {
        return epoch() >= _state.accounts[account].fluidUntil ? PoolAccount.Status.Frozen : PoolAccount.Status.Fluid;
    }

    /**
     * Epoch
     */

    function epoch() internal view returns (uint256) {
        return dao().epoch();
    }

    function bootstrappingAt(uint256 epoch) internal returns (bool) {
        return dao().bootstrappingAt(epoch);
    }

    function oracleCapture() internal returns (Decimal.D256 memory) {
        (Decimal.D256 memory price, bool valid) = dao().oracle().capture();

        if (dao().bootstrappingAt(epoch().sub(1))) {
            return Constants.getBootstrappingPrice();
        }

        if (!valid) {
            return Decimal.one();
        }

        return price;
    }

    /**
     * Staking Rewards
     */

    function stakingToken() public view returns (IERC20) {
        return _state.stakingToken;
    }

    function rewardsToken() public view returns (IERC20) {
        return _state.rewardsToken;
    }
}

