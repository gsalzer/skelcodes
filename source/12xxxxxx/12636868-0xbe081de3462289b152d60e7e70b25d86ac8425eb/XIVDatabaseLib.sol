// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

library XIVDatabaseLib{
    // deficoin struct for deficoinmappings..
    struct DefiCoin{
        uint16 oracleType;
        bool status;
        string currencySymbol;
    }
    struct TimePeriod{
        bool status;
        uint64 _days;
    }
     struct FlexibleInfo{
        uint128 id;
        uint16 upDownPercentage; //10**2
        uint16 riskFactor;       //10**2
        uint16 rewardFactor;     //10**2
        bool status;
    }
    struct FixedInfo{
        uint128 id;
        uint64 daysCount;// integer value
        uint16 upDownPercentage; //10**2
        uint16 riskFactor;       //10**2
        uint16 rewardFactor;     //10**2
        bool status;
    }
    struct IndexCoin{
        uint16 oracleType;
        address contractAddress;
        bool status;
        string currencySymbol;
        uint256 contributionPercentage; //10**2
    }
    struct BetPriceHistory{
        uint128 baseIndexValue;
        uint128 actualIndexValue;
    }
    struct LPLockedInfo{
        uint256 lockedTimeStamp;
        uint256 amountLocked;
    }
    struct BetInfo{
        uint256 coinType;
        uint256 principalAmount;
        uint256 currentPrice;
        uint256 timestamp;
        uint256 betTimePeriod;
        uint256 amount;
        address userAddress;
        address contractAddress;
        uint128 id;
        uint16 betType; //
        uint16 checkpointPercent;
        uint16 rewardFactor;
        uint16 riskFactor;
        uint16 status; // 0->bet active, 1->bet won, 2->bet lost, 3-> withdraw before result
    }
}


