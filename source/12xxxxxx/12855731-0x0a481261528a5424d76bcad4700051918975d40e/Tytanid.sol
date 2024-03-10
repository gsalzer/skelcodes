// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

contract Tytanid {
    enum Side{
        SHORT,
        LONG,
        TYTANID
    }

    enum Phase{
        BIDDING,
        TRADING,
        MATURITY,
        EXPIRED
    }

    struct Commissions {
        uint8 createMarketStake;
        uint8 joinMarketStake;
        uint8 exitMarketStake;
        uint8 joinMarketTytanidRatio;
        uint8 exitMarketTytanidRatio;
    }

    Commissions commissions;

    enum Category{
        CRYPTO,
        FIAT,
        COMMODITIES,
        EQUITY
    }

    enum AssetStatus{ACTIVE, INACTIVE}

    enum CurrencyStatus{ACTIVE, INACTIVE}

    enum BidStatus {
        ACTIVE,
        PAID,
        EXIT
    }

    struct SideSummary {
        uint24 participants;
        uint amount;
    }

    struct Bid {
        address bidder;
        Side side;
        uint amount;
        BidStatus status;
        uint32 joinMarketTime;
        uint32 exitMarketTime;
        uint32 payoutTime;
    }

    enum ActivityType {
        BID,
        EXIT,
        PAYOUT
    }

    enum LogoType {
        SVG,
        PNG
    }

    struct Activity {
        address bidderAddress;
        address marketAddress;
        ActivityType activityType;
        Side side;
        uint amount;
        uint32 activityTime;
    }

    struct Asset {
        string name;
        string fullName;
        Category category;
        address chainlinkAddress;
        string referenceTo;
        AssetStatus status;
        uint8 decimals;
        LogoType logoType;
    }

    struct Currency {
        string name;
        string fullName;
        address chainlinkAddress;
        string referenceTo;
        CurrencyStatus status;
        uint8 decimals;
    }
}

