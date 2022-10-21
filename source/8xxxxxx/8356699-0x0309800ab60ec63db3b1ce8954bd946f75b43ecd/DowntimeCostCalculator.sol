/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

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
pragma solidity ^0.5.11;

/// @title Ownable
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    constructor()
        public
    {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a
    ///      new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

/// @title Claimable
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev Extension for the Ownable contract, where the ownership needs
///      to be claimed. This allows the new owner to accept the transfer.
contract Claimable is Ownable
{
    address public pendingOwner;

    /// @dev Modifier throws if called by any account other than the pendingOwner.
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to set the pendingOwner address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    /// @dev Allows the pendingOwner address to finalize the transfer.
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

/// @title Utility Functions for uint
/// @author Daniel Wang - <daniel@loopring.org>
library MathUint
{
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function decodeFloat(
        uint f
        )
        internal
        pure
        returns (uint value)
    {
        uint numBitsMantissa = 23;
        uint exponent = f >> numBitsMantissa;
        uint mantissa = f & ((1 << numBitsMantissa) - 1);
        value = mantissa * (10 ** exponent);
    }
}

/// @title IDowntimeCostCalculator
/// @author Daniel Wang - <daniel@loopring.org>
contract IDowntimeCostCalculator
{
    /// @dev Returns the amount LRC required to purchase the given downtime.
    /// @param totalTimeInMaintenanceSeconds The total time a DEX has been in maintain mode.
    /// @param totalDEXLifeTimeSeconds The DEX's total life time since genesis.
    /// @param numDowntimeMinutes The current downtime balance in minutes before purchase.
    /// @param exchangeStakedLRC The number of LRC staked by the DEX's owner.
    /// @param durationToPurchaseMinutes The downtime in minute to purchase.
    /// @return cost The cost in LRC for purchasing the downtime.
    function getDowntimeCostLRC(
        uint  totalTimeInMaintenanceSeconds,
        uint  totalDEXLifeTimeSeconds,
        uint  numDowntimeMinutes,
        uint  exchangeStakedLRC,
        uint  durationToPurchaseMinutes
        )
        external
        view
        returns (uint cost);
}

/// @title The default IDowntimeCostCalculator implementation.
/// @author Daniel Wang  - <daniel@loopring.org>
contract DowntimeCostCalculator is Claimable, IDowntimeCostCalculator
{
    using MathUint for uint;

    uint public basePricePerMinute;
    uint public maxPenalty;
    uint public gracePeriodsMinutes;
    uint public gracePeriodPricePerMinute;
    uint public maxAwailableDowntimeMinutes;

    event SettingsUpdated(
        uint oldBasePricePerMinute,
        uint oldMaxPenalty,
        uint oldGracePeriodMinutes,
        uint oldGracePeriodPricePerMinute,
        uint oldMaxAwailableDowntimeMinutes
    );

    constructor() Claimable() public {}

    function getDowntimeCostLRC(
        uint  totalTimeInMaintenanceSeconds,
        uint  totalDEXLifeTimeSeconds,
        uint  numDowntimeMinutes,
        uint  /* exchangeStakedLRC */,
        uint  durationToPurchaseMinutes
        )
        external
        view
        returns (uint)
    {
        uint newCost = getTotalCost(
            totalTimeInMaintenanceSeconds,
            totalDEXLifeTimeSeconds,
            numDowntimeMinutes.add(durationToPurchaseMinutes)
        );

        uint oldCost = getTotalCost(
            totalTimeInMaintenanceSeconds,
            totalDEXLifeTimeSeconds,
            numDowntimeMinutes
        );

        return newCost > oldCost ? newCost - oldCost : 0;
    }

    function updateSettings(
        uint _basePricePerMinute,
        uint _maxPenalty,
        uint _gracePeriodsMinutes,
        uint _gracePeriodPricePerMinute,
        uint _maxAwailableDowntimeMinutes
        )
        external
        onlyOwner
    {
        require(
            _basePricePerMinute > 0 && _maxPenalty > 0 &&
            _gracePeriodPricePerMinute > 0 && _maxAwailableDowntimeMinutes > 0,
            "ZERO_VALUE"
        );
        require(_gracePeriodPricePerMinute <= _basePricePerMinute, "INVALID_PRICE");

        emit SettingsUpdated(
            basePricePerMinute,
            maxPenalty,
            gracePeriodsMinutes,
            gracePeriodPricePerMinute,
            maxAwailableDowntimeMinutes
        );

        basePricePerMinute = _basePricePerMinute;
        maxPenalty = _maxPenalty;
        gracePeriodsMinutes = _gracePeriodsMinutes;
        gracePeriodPricePerMinute = _gracePeriodPricePerMinute;
        maxAwailableDowntimeMinutes = _maxAwailableDowntimeMinutes;
    }

    function getTotalCost(
        uint totalTimeInMaintenanceSeconds,
        uint totalDEXLifeTimeSeconds,
        uint downtimeMinutes
        )
        private
        view
        returns (uint)
    {
        require(downtimeMinutes <= maxAwailableDowntimeMinutes, "PURCHASE_PROHIBITED");
        uint totalMinutes = downtimeMinutes.add(totalTimeInMaintenanceSeconds / 60);

        if (totalMinutes <= gracePeriodsMinutes) {
            return totalMinutes.mul(gracePeriodPricePerMinute);
        }

        uint timeBeyondGracePeriodMinutes = totalMinutes - gracePeriodsMinutes;
        uint penalty = timeBeyondGracePeriodMinutes.mul(600000) / totalDEXLifeTimeSeconds + 100;
        uint _maxPenalty = maxPenalty.mul(100);

        if (penalty > _maxPenalty) {
            penalty = _maxPenalty;
        }

        return gracePeriodsMinutes.mul(gracePeriodPricePerMinute).add(
            timeBeyondGracePeriodMinutes.mul(basePricePerMinute).mul(penalty) / 100
        );
    }
}
