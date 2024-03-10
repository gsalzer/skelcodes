// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.11;

contract TeazersStorage {
    uint8 public constant TOP_LEVEL = 16;
    uint32 public lastId;
    uint256 internal constant ENTRY_ENABLED = 1;
    uint256 internal constant ENTRY_DISABLED = 2;
    uint256 public constant REENTRY_REQ = 2;
    uint256 internal reentry_status;
    address internal owner;
    
    struct Account {
        uint32 id;
        uint32 directSales;
        uint8[] activeLevel;
        bool exists;
        address referrer;
        mapping(uint8 => X3) x3Positions;
        mapping(uint8 => X4) x4Positions;
    }

    struct X3 {
        uint8 passup;
        uint8 reEntryCheck;
        uint8 placement;
        uint16 cycles;
        uint32 directSales;
        address referrer;
    }

    struct X4 {
        uint8 passup;
        uint8 cycle;
        uint8 reEntryCheck;
        uint8 placementLastLevel;
        uint8 placementSide;
        uint16 cycles;
        uint32 directSales;
        address referrer;
        address placedUnder;
        address[] placementFirstLevel;
    }


    mapping(uint8 => uint256) public levelCost;
    mapping(address => Account) public users;
    mapping(uint32 => address) public idToAddress;

    modifier isOwner(address _user) {
        require(owner == _user, 'Restricted Access!');
        _;
    }

    modifier isMember(address _addr) {
        require(users[_addr].exists, 'Register Account First!');
        _;
    }

    modifier blockReEntry() {
        require(reentry_status != ENTRY_DISABLED, 'Security Block');
        reentry_status = ENTRY_DISABLED;

        _;
        reentry_status = ENTRY_ENABLED;
    }
}
