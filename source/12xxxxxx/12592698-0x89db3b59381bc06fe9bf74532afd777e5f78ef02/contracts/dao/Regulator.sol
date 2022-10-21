/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
import "./Comptroller.sol";
import "../external/Decimal.sol";
import "../Constants.sol";

contract Regulator is Comptroller {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    event SupplyIncrease(uint256 indexed epoch, uint256 epochPeriod, uint256 price, uint256 newRedeemable, uint256 lessDebt, uint256 newBonded);
    event SupplyDecrease(uint256 indexed epoch, uint256 epochPeriod, uint256 price, uint256 newDebt);
    event SupplyNeutral(uint256 indexed epoch, uint256 epochPeriod);

    function step() internal {
        Decimal.D256 memory price = oracleCapture();
        adjustPeriod(price);

        if (price.greaterThan(Decimal.one())) {
            setDebtToZero();
            growSupply(price);
            return;
        }

        if (price.lessThan(Decimal.one())) {
            decrementTotalRedeemable(totalRedeemable(), "Blockchain broke???????");
            shrinkSupply(price);
            return;
        }

        emit SupplyNeutral(epoch(), currentEpochDuration());
    }

    function shrinkSupply(Decimal.D256 memory price) private {
        Decimal.D256 memory delta = limit(Decimal.one().sub(price));
        uint256 newDebt = delta.mul(totalNet()).asUint256();
        increaseDebt(newDebt);

        emit SupplyDecrease(epoch(), currentEpochDuration(), price.value, newDebt);
        return;
    }

    function growSupply(Decimal.D256 memory price) private {
        Decimal.D256 memory delta = limit(price.sub(Decimal.one()).div(Constants.getSupplyChangeDivisor()));
        uint256 newSupply = delta.mul(totalNet()).asUint256();
        (uint256 newRedeemable, uint256 lessDebt, uint256 newBonded) = increaseSupply(newSupply);
        emit SupplyIncrease(epoch(), currentEpochDuration(), price.value, newRedeemable, lessDebt, newBonded);
    }

    function limit(Decimal.D256 memory delta) internal view returns (Decimal.D256 memory) {
        Decimal.D256 memory supplyChangeLimit = Constants.getSupplyChangeLimit();

        return delta.greaterThan(supplyChangeLimit) ? supplyChangeLimit : delta;
    }

    function oracleCapture() private returns (Decimal.D256 memory) {
        (Decimal.D256 memory price, bool valid) = oracle().capture();

        if (bootstrappingAt(epoch().sub(1))) {
            return Constants.getBootstrappingPrice();
        }
        if (!valid) {
            return Decimal.one();
        }

        return price;
    }
}

