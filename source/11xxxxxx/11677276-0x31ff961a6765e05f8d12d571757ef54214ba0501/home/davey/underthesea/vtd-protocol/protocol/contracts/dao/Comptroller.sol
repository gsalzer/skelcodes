/*
    Copyright 2020 VTD team, based on the works of Dynamic Dollar Devs and Empty Set Squad

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
import "./Setters.sol";
import "./PeggingSystem.sol";
import "../external/Require.sol";

contract Comptroller is Setters, PeggingSystem {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Comptroller";

    function mintToAccount(address account, uint256 amount) internal {
        dollar().mint(account, amount);
        if (!bootstrappingAt(epoch())) {
            increaseDebt(amount);
        }

        balanceCheck();
    }

    function burnFromAccount(address account, uint256 amount) internal {
        dollar().transferFrom(account, address(this), amount);
        dollar().burn(amount);
        decrementTotalDebt(amount, "Comptroller: not enough outstanding debt");

        balanceCheck();
    }

    function redeemToAccount(address account, uint256 amount) internal {
        dollar().transfer(account, amount);
        decrementTotalRedeemable(amount, "Comptroller: not enough redeemable balance");

        balanceCheck();
    }

    function burnRedeemable(uint256 amount) internal {
        dollar().burn(amount);
        decrementTotalRedeemable(amount, "Comptroller: not enough redeemable balance");

        balanceCheck();
    }

    function increaseDebt(uint256 amount) internal {
        incrementTotalDebt(amount);
        resetDebt(Constants.getDebtRatioCap());

        balanceCheck();
    }

    function decreaseDebt(uint256 amount) internal {
        decrementTotalDebt(amount, "Comptroller: not enough debt");

        balanceCheck();
    }

    function increaseSupply(uint256 newSupply) internal returns (uint256, uint256, uint256) {
        (uint256 newRedeemable, uint256 lessDebt, uint256 poolReward) = (0, 0, 0);

        // 1. True up redeemable pool
        uint256 totalRedeemable = totalRedeemable();
        uint256 totalCoupons = totalCoupons();
        if (totalRedeemable < totalCoupons) {

            // Get new redeemable coupons
            newRedeemable = totalCoupons.sub(totalRedeemable);
            // Pad with Pool's potential cut
            newRedeemable = newRedeemable.mul(100).div(SafeMath.sub(100, Constants.getOraclePoolRatio()));
            // Cap at newSupply
            newRedeemable = newRedeemable > newSupply ? newSupply : newRedeemable;
            // Determine Pool's final cut
            poolReward = newRedeemable.mul(Constants.getOraclePoolRatio()).div(100);
            // Determine Redeemable's final cut
            newRedeemable = newRedeemable.sub(poolReward);

            mintToPool(poolReward);
            mintToRedeemable(newRedeemable);

            newSupply = newSupply.sub(poolReward);
            newSupply = newSupply.sub(newRedeemable);
        }
        // 2. Eliminate debt
        uint256 totalDebt = totalDebt();
        if (newSupply > 0 && totalDebt > 0) {
            lessDebt = totalDebt > newSupply ? newSupply : totalDebt;
            decreaseDebt(lessDebt);

            newSupply = newSupply.sub(lessDebt);
        }

        // 3. Payout to bonded
        if (totalBonded() == 0) {
            newSupply = 0;
        }
        if (newSupply > 0) {
            mintToBonded(newSupply);
        }

        return (newRedeemable, lessDebt, newSupply.add(poolReward));
    }

    function resetDebt(Decimal.D256 memory targetDebtRatio) internal {
        uint256 targetDebt = targetDebtRatio.mul(dollar().totalSupply()).asUint256();
        uint256 currentDebt = totalDebt();

        if (currentDebt > targetDebt) {
            uint256 lessDebt = currentDebt.sub(targetDebt);
            decreaseDebt(lessDebt);
        }
    }

    function balanceCheck() private {
        Require.that(
            dollar().balanceOf(address(this)) >= totalBonded().add(totalStaged()).add(totalRedeemable()),
            FILE,
            "Inconsistent balances"
        );
    }

    function mintToBonded(uint256 amount) private {
        Require.that(
            totalBonded() > 0,
            FILE,
            "Cant mint to empty pool"
        );

        uint256 poolAmount = amount.mul(Constants.getOraclePoolRatio()).div(100);
        uint256 daoAmount = amount > poolAmount ? amount.sub(poolAmount) : 0;

        mintToPool(poolAmount);
        mintToDAO(daoAmount);

        balanceCheck();
    }

    function mintToDAO(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(address(this), amount);
            incrementTotalBonded(amount);
        }
    }

    function mintToPool(uint256 amount) private {
        if (amount > 0) {
            (Decimal.D256 memory dsdShare, Decimal.D256 memory usdtShare, Decimal.D256 memory ethShare, Decimal.D256 memory wbtcShare, Decimal.D256 memory usdcShare) = updateLiquidityForAllPools();
        //   adds 1 to avoid dealing with zeros
            dollar().mint(Constants.getDsdPool(), dsdShare.mul(amount).asUint256().add(1));
            dollar().mint(Constants.getUsdtPool(), usdtShare.mul(amount).asUint256().add(1));
            dollar().mint(Constants.getEthPool(), ethShare.mul(amount).asUint256().add(1));
            dollar().mint(Constants.getWbtcPool(), wbtcShare.mul(amount).asUint256().add(1));
            dollar().mint(Constants.getUsdcPool(), usdcShare.mul(amount).asUint256().add(1));
        }
    }

    function mintToRedeemable(uint256 amount) private {
        dollar().mint(address(this), amount);
        incrementTotalRedeemable(amount);

        balanceCheck();
    }
}

