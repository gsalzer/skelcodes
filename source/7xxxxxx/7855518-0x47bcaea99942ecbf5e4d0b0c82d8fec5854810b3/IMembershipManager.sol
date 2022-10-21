pragma solidity >=0.5.3 < 0.6.0;

/// @author Ryan @ Protea 
/// @title IMembershipManager
interface IMembershipManager {
    struct RegisteredUtility{
        bool active;
        mapping(uint256 => uint256) lockedStakePool; // Total Stake withheld by the utility
        mapping(uint256 => mapping(address => uint256)) contributions; // Traking individual token values sent in
    }

    struct Membership{
        uint256 currentDate;
        uint256 availableStake;
        uint256 reputation;
    }

    event UtilityAdded(address issuer);
    event UtilityRemoved(address issuer);
    event ReputationRewardSet(address indexed issuer, uint8 id, uint256 amount);

    event StakeLocked(address indexed member, address indexed utility, uint256 tokenAmount);
    event StakeUnlocked(address indexed member, address indexed utility, uint256 tokenAmount);

    event MembershipStaked(address indexed member, uint256 tokensStaked);
   
    function initialize(address _tokenManager) external returns(bool);

    function addUtility(address _utility) external;

    function removeUtility(address _utility) external;

    function addAdmin(address _newAdmin) external;

    function addSystemAdmin(address _newAdmin) external;

    function removeAdmin(address _newAdmin) external;

    function removeSystemAdmin(address _newAdmin) external;

    function setReputationRewardEvent(address _utility, uint8 _id, uint256 _rewardAmount) external;

    function issueReputationReward(address _member, uint8 _rewardId) external returns (bool);
  
    function stakeMembership(uint256 _daiValue, address _member) external returns(bool);

    function manualTransfer(uint256 _tokenAmount, uint256 _index, address _member) external returns (bool);

    function withdrawMembership(uint256 _daiValue, address _member) external returns(bool);

    function lockCommitment(address _member, uint256 _index, uint256 _daiValue) external returns (bool);

    function unlockCommitment(address _member, uint256 _index, uint8 _reputationEvent) external returns (bool);

    function reputationOf(address _account) external view returns(uint256);

    function getMembershipStatus(address _member) external view returns(uint256, uint256, uint256);

    function getUtilityStake(address _utility, uint256 _index) external view returns(uint256);
    
    function getMemberUtilityStake(address _utility, address _member, uint256 _index) external view returns(uint256);

    function getReputationRewardEvent(address _utility, uint8 _id) external view returns(uint256);

    function tokenManager() external view returns(address);
}
