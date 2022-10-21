pragma solidity ^0.6.0;
contract Vars{
    uint256 public activationCharges = 0.255 ether; // fee paid to activate/join the game, 0.005 register charge fee will go to owner, rest will be distributed to uplines
    uint256 public activationPeriod = 120 days; // expiration time since day of joining
    uint256 public currentLevel = 1; // current level where people can join, 0 level is for the main wallet
    uint256 public currentUserId = 0; // current active Id that will be assigned to the person who join, 0 Id is for the main wallet
    uint256 occupiedSlots = 0; // slots that are already occupied in each level
    uint256 public totalMembers = 0; // slots that are already occupied in each level
    address payable public owner;

    bool stop;
    struct User{
        bool isExist;
        uint256 id;
        uint256 totalReferrals;
        uint256 deadline;
        uint256 level;
        address referer;
        bytes32 referralLink;
        address initialInviter;
    }
    
    mapping(address => User) public users; // stores information about users based on their addresses
    mapping(bytes32 => address) hashedIds; // stores the refferal codes for each user based on their addresses
    mapping(uint256 => address payable) userList; // stores the address of each user based on the Id assigned

    
    event OwnerFundsTransfer(uint256 amount, uint256 fromLevel, uint256 fromSlotId);
    event UplineFundsDistributed(uint256 amount, uint256 fromLevel, uint256 fromSlotId);
    event UserFundsTransfer(address user, uint256 amount, uint256 fromLevel, uint256 fromSlotId);
    event UserRegistered(address user, uint256 level, uint256 slotId, uint256 expiresAt);
    event UserActivated(address user, uint256 level, uint256 slotId, uint256 expiresAt);
    event UserReferred(address referrer, uint256 referred);
}
