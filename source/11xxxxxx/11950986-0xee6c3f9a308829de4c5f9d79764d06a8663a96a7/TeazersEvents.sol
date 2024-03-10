// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.11;

contract TeazersEvents {
    event Registration(address member, uint256 memberId, address referrer);
    event Upgrade(address member, address referrer, uint8 matrix, uint8 level);
    
    event PlacementX3(
        address member,
        address referrer,
        uint8 level,
        uint8 placement,
        bool passup
    );
    
    event PlacementX4(
        address member,
        address referrer,
        uint8 level,
        uint8 placementSide,
        address placedUnder,
        bool passup
    );
    
    event Cycle(
        address indexed member,
        address fromPosition,
        uint8 matrix,
        uint8 level
    );
    event PlacementReEntry(
        address indexed member,
        address reEntryFrom,
        uint8 matrix,
        uint8 level
    );
    event FundsPayout(
        address indexed member,
        address payoutFrom,
        uint8 matrix,
        uint8 level
    );
    event FundsPassup(
        address indexed member,
        address passupFrom,
        uint8 matrix,
        uint8 level
    );
}
