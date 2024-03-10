pragma solidity >=0.5.3 < 0.6.0;

import { IERC20 } from "./IERC20.sol";
import { SafeMath } from "./SafeMath.sol";
import { Roles } from "./Roles.sol";
import { ITokenManager } from "./ITokenManager.sol";
import { AdminManaged } from "./AdminManaged.sol";

// Use Library for Roles: https://openzeppelin.org/api/docs/learn-about-access-control.html

/// @author Ryan @ Protea
/// @title V1 Membership Manager
contract MembershipManagerV1 is AdminManaged {
    using SafeMath for uint256;
    using Roles for Roles.Role;

    address internal tokenManager_;
    uint8 internal membershipTypeTotal_;

    bool internal disabled = false;

    Roles.Role internal systemAdmins_;

    mapping(address => RegisteredUtility) internal registeredUtility_;
    mapping(address => mapping (uint8 => uint256)) internal reputationRewards_;

    mapping(address => Membership) internal membershipState_;

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
    event MembershipWithdrawn(address indexed member, uint256 tokensWithdrawn);

    /// @param _communityManager    The first admin and publisher of the community
    constructor(address _communityManager)
        public
        AdminManaged(_communityManager)
    {
        systemAdmins_.add(_communityManager);
        systemAdmins_.add(msg.sender); // This allows the deployer to set the membership manager
        admins_.add(msg.sender);
    }

    modifier onlySystemAdmin() {
        require(systemAdmins_.has(msg.sender), "User not authorised");
        _;
    }

    modifier onlyUtility(address _utilityAddress){
        require(registeredUtility_[_utilityAddress].active, "Address is not a registered utility");
        _;
    }

    modifier notDisabled() {
        require(disabled == false, "Membership manager locked for migration");
        _;
    }

    /// @dev    Used to initalise the contract after the token manager is deployed
    /// @param _tokenManager    :address The address of the new token manager
    /// @return bool            Returns a bool for requires to validate
    function initialize(address _tokenManager) external onlySystemAdmin returns(bool) {
        require(tokenManager_ == address(0), "Contracts initalised");
        tokenManager_ = _tokenManager;
        systemAdmins_.remove(msg.sender);
        admins_.remove(msg.sender);
        return true;
    }

    /// @dev    Used to lock all incomming token functions & reputation for migrating to a new manager
    /// @return bool            Returns a bool for requires to validate
    function disableForMigration() external onlySystemAdmin returns(bool) {
        disabled = true;
        return disabled;
    }


    /// @dev    Used to register a utility for access to the membership manager
    /// @param _utility         :address The utility in question
    // Rough gas usage 44,950
    function addUtility(address _utility) external onlyAdmin{
        registeredUtility_[_utility].active = true;
        emit UtilityAdded(_utility);
    }

    /// @dev    Used to remove a utility's access from the membership manager
    /// @param _utility         :address The utility in question
    function removeUtility(address _utility) external onlyAdmin {
        registeredUtility_[_utility].active = false;
        emit UtilityRemoved(_utility);
    }

    /// @dev    Used to add an admin
    /// @param _newAdmin        :address The address of the new admin
    function addAdmin(address _newAdmin) external onlyAdmin {
        admins_.add(_newAdmin);
    }

    /// @dev    Used to add a system admin
    /// @param _newAdmin        :address The address of the new admin
    function addSystemAdmin(address _newAdmin) external onlySystemAdmin {
        systemAdmins_.add(_newAdmin);
    }

    /// @dev    Used to remove admins
    /// @param _oldAdmin        :address The address of the previous admin
    function removeAdmin(address _oldAdmin) external onlyAdmin {
        admins_.remove(_oldAdmin);
    }

    /// @dev    Used to remove system admins
    /// @param _oldAdmin        :address The address of the previous admin
    function removeSystemAdmin(address _oldAdmin) external onlySystemAdmin {
        systemAdmins_.remove(_oldAdmin);
    }

    /// @dev    Registers a reputation incrementing event for a utility to use
    /// @param _utility         :address    The utility in question
    /// @param _id              :uint8      The registered reputation increment
    /// @param _rewardAmount    :uint256    The amount that the event adds to a users reputation
    // Rough gas usage 45,824
    function setReputationRewardEvent(address _utility, uint8 _id, uint256 _rewardAmount) external onlySystemAdmin{
        reputationRewards_[_utility][_id] = _rewardAmount;
        emit ReputationRewardSet(_utility, _id, _rewardAmount);
    }

    /// @dev    Used by utilities to increment a users reputation values
    /// @param _member          :address    The member address
    /// @param _rewardId        :uint8      The registered reputation increment
    /// @return bool            Returns a bool for requires to validate
    function issueReputationReward(address _member, uint8 _rewardId) public notDisabled() onlyUtility(msg.sender) returns (bool) {
        membershipState_[_member].reputation = membershipState_[_member].reputation.add(reputationRewards_[msg.sender][_rewardId]);
        return true;
    }

    /// @dev    Used to inject tokens for utility access into a users membership account
    /// @param _daiValue        :uint256    The value in DAI of tokens to extract
    /// @param _member          :address    The member address
    /// @return bool            Returns a bool for requires to validate
    // Rough gas usage 102,245
    function stakeMembership(uint256 _daiValue, address _member) external notDisabled() returns(bool) {
        uint256 requiredTokens = ITokenManager(tokenManager_).colateralToTokenSelling(_daiValue);
        require(ITokenManager(tokenManager_).transferFrom(_member, address(this), requiredTokens), "Transfer was not complete");
        if(membershipState_[_member].currentDate == 0){
            membershipState_[_member].currentDate = now;
        }
        membershipState_[_member].availableStake = membershipState_[_member].availableStake.add(requiredTokens);

        emit MembershipStaked(_member, requiredTokens);
        return true;
    }

    /// @dev    Used to manually send tokens sitting in a utility pool, either unclaimed or requiring distribution by the utility
    /// @param _tokenAmount     :uint256    The amount of community tokens to send
    /// @param _index           :uint256    The utility activity index
    /// @param _member          :address    The member address
    /// @return bool            Returns a bool for requires to validate
    function manualTransfer(uint256 _tokenAmount, uint256 _index, address _member) external onlyUtility(msg.sender) returns (bool) {
        require(registeredUtility_[msg.sender].lockedStakePool[_index] >= _tokenAmount, "Insufficient tokens available");

        registeredUtility_[msg.sender].lockedStakePool[_index] = registeredUtility_[msg.sender].lockedStakePool[_index].sub(_tokenAmount);
        membershipState_[_member].availableStake = membershipState_[_member].availableStake.add(_tokenAmount);

        return true;
    }

    /// @dev    Used to extract tokens from the membership manager to the users account
    /// @param _daiValue        :uint256    The value in DAI of tokens to extract
    /// @param _member          :address    The member address
    /// @return bool            Returns a bool for requires to validate
    function withdrawMembership(uint256 _daiValue, address _member) external returns(bool) {
        uint256 withdrawAmount = ITokenManager(tokenManager_).colateralToTokenSelling(_daiValue);
        require(membershipState_[_member].availableStake >= withdrawAmount, "Not enough stake to fulfil request");
        membershipState_[_member].availableStake = membershipState_[_member].availableStake.sub(withdrawAmount);
        require(ITokenManager(tokenManager_).transfer(_member, withdrawAmount), "Transfer was not complete");
        emit MembershipWithdrawn(_member, withdrawAmount);
    }

    /// @dev    Used to lock up tokens for access to a utilities features
    /// @param _member          :address    The member address
    /// @param _index           :uint256    The utility activity index
    /// @param _daiValue        :uint256    The value in DAI of tokens needed to use the utility
    /// @return bool            Returns a bool for requires to validate
    function lockCommitment(address _member, uint256 _index, uint256 _daiValue) external notDisabled() onlyUtility(msg.sender) returns (bool) {
        uint256 requiredTokens = ITokenManager(tokenManager_).colateralToTokenSelling(_daiValue);
        require(membershipState_[_member].availableStake >= requiredTokens, "Not enough available commitment");
        require(msg.sender != _member, "Address invalid");

        membershipState_[_member].availableStake = membershipState_[_member].availableStake.sub(requiredTokens);

        registeredUtility_[msg.sender].contributions[_index][_member] = registeredUtility_[msg.sender].contributions[_index][_member].add(requiredTokens);
        registeredUtility_[msg.sender].lockedStakePool[_index] = registeredUtility_[msg.sender].lockedStakePool[_index].add(requiredTokens);

        emit StakeLocked(_member, msg.sender, requiredTokens);

        return true;
    }

    /// @dev    Used to return stake to a user having previously been locked up in a utility for use
    /// @param _member          :address    The member address
    /// @param _index           :uint256    The utility activity index
    /// @return bool            Returns a bool for requires to validate
    function unlockCommitment(address _member, uint256 _index, uint8 _reputationEvent) external onlyUtility(msg.sender) returns (bool) {
        uint256 returnAmount = registeredUtility_[msg.sender].contributions[_index][_member];

        require(registeredUtility_[msg.sender].lockedStakePool[_index] >= returnAmount, "Insufficient tokens available");
        registeredUtility_[msg.sender].contributions[_index][_member] = 0;
        registeredUtility_[msg.sender].lockedStakePool[_index] = registeredUtility_[msg.sender].lockedStakePool[_index].sub(returnAmount);

        membershipState_[_member].availableStake = membershipState_[_member].availableStake.add(returnAmount);
        require(issueReputationReward(_member, _reputationEvent), "Reputation not increased");
        emit StakeUnlocked(_member, msg.sender, returnAmount);
        return true;
    }

    /// @dev    Returns the details on a members contributions, reputation and date data
    /// @param _member          :address    The member address
    /// @return (uint256, uint256, uint256)     The date field, reputation and current available stake
    function getMembershipStatus(address _member)
        public
        view
        returns(uint256, uint256, uint256)
    {
        return (
            membershipState_[_member].currentDate,
            membershipState_[_member].reputation,
            membershipState_[_member].availableStake
        );
    }

    /// @dev    Checks if an address is a registered or active utility
    /// @param _utility         :address    Address to check if is a registered utility
    /// @return bool            Bool stating if valid
    function isRegistered(address _utility) external view returns(bool) {
        return registeredUtility_[_utility].active;
    }

    /// @dev    Used to see the total amount of contributions sitting in a utility's activity
    /// @param _utility         :address    The utility in question
    /// @param _index           :uint256    The utility activity index
    /// @return uint256         Total active contributions locked up but the activity
    function getUtilityStake(address _utility, uint256 _index) external view returns(uint256) {
        return registeredUtility_[_utility].lockedStakePool[_index];
    }

    /// @dev    Used to track the contribution of tokens a user has sent to the utility's activity
    /// @param _utility         :address    The utility in question
    /// @param _member          :address    The member contributing
    /// @param _index           :uint256    The utility activity index
    /// @return uint256         Current contribution for that member on the utility activty
    function getMemberUtilityStake(address _utility, address _member, uint256 _index) external view returns(uint256) {
        return registeredUtility_[_utility].contributions[_index][_member];
    }

    /// @dev    Used to check the current reward amount for the utilities reputation increasing event
    /// @param _utility         :address    The utility in question
    /// @param _id              :uint8      The registered reputation increment
    /// @return uint256         The amount that the event adds to a users reputation
    function getReputationRewardEvent(address _utility, uint8 _id) external view returns(uint256){
        return reputationRewards_[_utility][_id];
    }

    /// @dev    Used to return the registered token manager, works like an initialisation check
    /// @return                 :address Token manager address
    function tokenManager() external view returns(address) {
        return tokenManager_;
    }

}
