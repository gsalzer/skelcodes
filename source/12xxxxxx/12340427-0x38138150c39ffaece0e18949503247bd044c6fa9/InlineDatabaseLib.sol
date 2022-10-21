// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

library InlineDatabaseLib{
    // deficoin struct for deficoinmappings..
   struct DefiCoin{
        uint16 oracleType;
        string currencySymbol;
        bool status;
    }
    struct TimePeriod{
        uint256 _days;
        bool status;
    }
     struct FlexibleInfo{
        uint256 id;
        uint16 upDownPercentage; //10**2
        uint16 riskFactor;       //10**2
        uint16 rewardFactor;     //10**2
        bool status;
    }
    struct FixedInfo{
        uint256 id;
        uint256 daysCount;// integer value
        uint16 upDownPercentage; //10**2
        uint16 riskFactor;       //10**2
        uint16 rewardFactor;     //10**2
        bool status;
    }
    struct IndexCoin{
        uint16 oracleType;
        string currencySymbol;
        address contractAddress;
        bool status;
        uint256 contributionPercentage; //10**2
    }
    struct BetPriceHistory{
        uint256 baseIndexValue;
        uint256 actualIndexValue;
    }
    struct LPLockedInfo{
        uint256 lockedTimeStamp;
        uint256 amountLocked;
    }
    struct StakingInfo{
        uint256 investmentId;
        uint256 stakeAmount;
    }
    struct IncentiveInfo{
        uint256 tillInvestmentId;
        uint256 incentiveAmount;
        uint256 totalAmountStakedAtIncentiveTime;
    }
    struct BetInfo{
        uint256 id;
        uint256 principalAmount;
        uint256 amount;
        address userAddress;
        address contractAddress;
        uint256 betType; //
        uint256 currentPrice;
        uint256 timestamp;
        uint256 betTimePeriod;
        uint16 checkpointPercent;
        uint16 rewardFactor;
        uint16 riskFactor;
        uint256 adminCommissionFee;
        uint16 status; // 0->bet active, 1->bet won, 2->bet lost, 3-> withdraw before result
    }
}

