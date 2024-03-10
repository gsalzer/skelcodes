pragma solidity ^0.8.6;

// SPDX-License-Identifier: Apache-2.0

library Subscription {
    struct Tier {
        string name;
        uint256 level;
        uint256 price;
    }

    struct Subscriber {
        address wallet;
        uint256 tier;
        uint256 expiration;
    }
}

