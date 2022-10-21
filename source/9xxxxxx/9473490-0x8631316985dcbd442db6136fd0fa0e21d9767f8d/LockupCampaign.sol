pragma solidity >= 0.5.3 < 0.6.0;

import "./SafeMath.sol";
import "./TimestampMonthConv.sol";
import "./ERC20Interface.sol";
//import "./ERC223ReceivingContract.sol";

//  Ownership contract
//  - token contract ownership for owner & lockup addresses

contract Ownership {
    address private _owner;
    
    event OwnerOwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    
    // Returns contract owner address
    function owner() public view returns (address){
        return _owner;
    }
    
    // Check if caller is owner account
    function isOwner() public view returns (bool){
        return (msg.sender == _owner);
    }
    
    // Modifier for function restricted to owner only
    modifier onlyOwner() {
        require(isOwner(), "Ownership: the caller is not the owner address");
        _;
    }
    
    // Transfer owner's ownership to new address
    // # param newOwner: address of new owner to be transferred
    function transferOwnerOwnership(address newOwner) public onlyOwner {
        _transferOwnerOwnership(newOwner);
    }
    
    // ==== internal functions ====

    function _transferOwnerOwnership(address newOwner) internal {
        require (newOwner != address(0), "Ownable: new owner is zero address");
        emit OwnerOwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function _setupOwnership(address own) internal {
        require (own != address(0), "Ownable: owner is zero address");
        _owner = own;
        
        emit OwnerOwnershipTransferred(address(0), own);
    }
}

contract LockupCampaign is Ownership {
    using SafeMath for uint256;
    using TimestampMonthConv for uint;
    
    enum LockStatus {NULL, LOCKED, UNLOCKED, RELEASED}
    
    struct WowbitInfo {
        uint256 totalLocked;
        uint256 totalExtraGiven;
        uint256 currentLocked;
        uint256 incentive3;
        uint256 incentive6;
        uint256 incentive9;
    }
    
    struct ParticipatingUsers {
        uint256 amountWWB;
        uint256 month;
        uint256 lockEnd;
        bool incCalculated;
        LockStatus status;
    }
    
    struct UsersExtraTokens {
        address[] exTokenAddress;
        uint8[] exTokenDecimals;
        uint256[] exTokenAmount;
    }
    
    WowbitInfo public wwbInfo;
    address public wwbAddress;
    address[] public tokenAddresses;
    uint8[] public tokenDecimals;
    bool public firstSet = false;
    mapping (address => ParticipatingUsers) internal userList;
    mapping (address => UsersExtraTokens) internal extraList;
    
    event PreRegister(address indexed _userAddress);
    event ConfirmRegister(address indexed _userAddress, uint256 startLock, uint256 endLock);
    event TokenLocked(address indexed _userAddress, uint256 amount);
    event TokenUnlocked(address indexed _userAddress, uint256 timestamp);
    event TokenReleased(address indexed _userAddress, uint256 amount);
    event RegisterEtcToken(address indexed _token);
    event RemoveEtcToken(address indexed _token);
    event EtcTokenRequested(address indexed _userAddress, address indexed _tokenAddress);
    event EtcTokenReleased(address indexed _userAddress, address indexed _tokenAddress, uint256 _amountIncentives);
    
    constructor(address owner, address WwbTokenAddress) public{
        _setupOwnership(owner);
        wwbAddress = WwbTokenAddress;
    }
    
    // --------------- ERC223 token fallback function ---------------
    
    // ERC223 supported tokenFallback: use erc223 transfer from token contract
    function tokenFallback(address _from, uint _value, bytes memory _data) public {
        string memory str = string(_data);
        if(_from == owner()){
            require((keccak256(abi.encodePacked((str))) == keccak256(abi.encodePacked(("supply")))),
                    "LockupCampaign: bytes command not authorized");
            // balance can be require from wwbTokenBalance() / otherTokenBalance()
        } else if(_from != owner()){
            require(userList[_from].lockEnd == 0, "LockupCampaign: user not registered");
            _confirmRegister(_from, _value);
            emit TokenLocked(_from, _value);
        } else {
            revert("LockupCampaign: not authorized");
        }
    }
    
    // --------------- ERC20 token deposit function ---------------
    
    // ERC20 deposit function: owner needs to approve token using `approve()` function in respective participating ERC20 token contract
    // before using this function (only owner function).
    // # params erc20TokenAddress: address of the token to deposit
    // # params amountToken: amount of token to deposit in contract
    function depositApprovedERC20(address erc20TokenAddress, uint256 amountToken) public onlyOwner {
        ERC20Interface(erc20TokenAddress).transferFrom(msg.sender, address(this), amountToken);
    }
    
    // --------------- WWB tokens functions ---------------
    
    // Set the percentage interest rates (where 7% = 700) for respective months for WWB token (only owner function).
    // # params rate_3month: percentage rate in 3 months
    // # params rate_6month: percentage rate in 6 months
    // # params rate_9month: percentage rate in 9 months
    function setWwbRate(uint256 rate_3month, uint256 rate_6month, uint256 rate_9month) public onlyOwner {
        _setWwbRate(rate_3month, rate_6month, rate_9month);
    }
    
    // Retrieve the balance of WWB tokens in this contract.
    // * returns (uint256): the amount of token in the contract
    function wwbTokenBalance() public view returns (uint256){
        return ERC20Interface(wwbAddress).balanceOf(address(this));
    }
    
    // Returns all WWB tokens back to the owner (only owner function).
    function returnAllWWBTokens() public onlyOwner {
        ERC20Interface(wwbAddress).transfer(owner(), ERC20Interface(wwbAddress).balanceOf(address(this)));
    }

    // Returns WWB information (only owner function).
    function getWwbInfo() public view onlyOwner returns (uint256, uint256, uint256, uint256, uint256, uint256){
        return (wwbInfo.totalLocked, wwbInfo.totalExtraGiven, wwbInfo.currentLocked, wwbInfo.incentive3, wwbInfo.incentive6, wwbInfo.incentive9);
    }
    
    // --------------- participating tokens functions ---------------
    
    // Retrieve if token address is a participating token in lockup campaign.
    // # params tokenAddress: address of the participating token
    // * returns (bool): indication of token participation
    function isParticipatingTokens(address tokenAddress) public view returns(bool){
        for(uint i = 0; i < tokenAddresses.length; i++){
            if(tokenAddresses[i] == tokenAddress) {
                return true;
            }
        }
    }

    // Retrieve the balance of participating tokens in this contract.
    // # params tokenAddress: address of the participating token
    // * returns (uint256): the amount of participating token in the contract
    function participatingTokenBalance(address tokenAddress) public view returns (uint256){
        return ERC20Interface(tokenAddress).balanceOf(address(this));
    }
    
    // Adds the participating tokens to be involved in lockup campaign
    // # params tokenAddress: address of the participating token
    // # params decimals: decimal of the participating token
    function addParticipatingToken(address tokenAddress, uint8 decimals) public onlyOwner {
        require(!isParticipatingTokens(tokenAddress), "LockupCampaign: token data exists");
        require(tokenAddress != address(0), "LockupCampaign: token contract address is zero");
        require(decimals != 0, "LockupCampaign: token contract decimals is zero");
        require(decimals <= 18, "LockupCampaign: token contract decimals invalid");
        tokenAddresses.push(tokenAddress);
        tokenDecimals.push(decimals);

        emit RegisterEtcToken(tokenAddress);
    }
    
    // Edit the registered participating tokens rates
    // # params tokenAddress: address of the participating token
    // # params incentive_6month: amount of token to be given for 6 month lock period
    // # params incentive_9month: amount of token to be given for 9 month lock period
    function removeParticipatingToken(address tokenAddress) public onlyOwner {
        for (uint i = 0; i < tokenAddresses.length; i++){
            if(tokenAddresses[i] == tokenAddress){
                tokenAddresses[i] = tokenAddresses[i+1];
                tokenDecimals[i] = tokenDecimals[i+1];
            }
        }
        tokenAddresses.length--;
        tokenDecimals.length--;
        emit RemoveEtcToken(tokenAddress);
    }
    
    // Returns all participating tokens to owner
    // # params tokenAddress: address of the participating token
    function returnAllOtherTokens(address tokenAddress) public onlyOwner {
        ERC20Interface(tokenAddress).transfer(owner(), ERC20Interface(tokenAddress).balanceOf(address(this)));
    }
    
    // --------------- register participants functions ---------------

    // Checks whether the use have registered (pre-registered, not sent token to contract yet for lockup)
    // # params userAddress: address of pre-registered user
    // * returns (bool): indication whether user have pre-registered (true) or not registered (false)
    function isPreParticipant(address userAddress) public view returns (bool) {
        return (userList[userAddress].month != 0);
    }

    // Checks whether the use have registered (already sent token to contract for lockup)
    // # params userAddress: address of registered user
    // * returns (bool): indication whether user have pre-registered (true) or not registered (false)
    function isRegisteredParticipant(address userAddress) public view returns (bool){
        return (userList[userAddress].lockEnd != 0);
    }

    // Returns user's current lock amount
    // # params userAddress: address of registered user
    // * returns (uint256): amount of user's token locked in contract
    function getParticipantLockAmount(address userAddress) public view returns (uint256){
        return userList[userAddress].amountWWB;
    }

    // Returns the registered user's lock info
    // # params userAddress: address of registered user
    // * returns (uint256): amount of user's token locked in contract
    // * returns (uint256): month of token lockup
    // * returns (uint256): end date of token's lockup period (unix timestamp)
    // * returns (bool): indication of user's locked token have been calculated or not
    // * returns (uint256): indication whether token has been unlocked or not
    function getParticipantInfo(address userAddress) public view returns (uint256, uint256, uint256, bool, bool){
        return(userList[userAddress].amountWWB, userList[userAddress].month,
               userList[userAddress].lockEnd, userList[userAddress].incCalculated,
               _getLockStatus(userList[userAddress].status)
        );
    }

    // Returns if user have applied for additional tokens
    // # params userAddress: address of registered user
    // * returns (bool): indication whether user have applied for additional token
    function isParticipantExtraTokens(address user) public view returns (bool){
        return (extraList[user].exTokenAddress.length != 0);
    }

    // Returns the data of additional token requested
    // # params userAddress: address of registered user
    // * returns (address[]): array of participating token contract address
    // * returns (uint256[]): array of amount of respective participating tokens should be given out
    function getParticipantExtraTokens(address user) public view returns (address[] memory, uint256[] memory){
        return (extraList[user].exTokenAddress, extraList[user].exTokenAmount);
    }
    
    // Updates the user's info on current time
    // # params userAddress: address of registered user
    function updateParticipantInfo(address userAddress) public {
        _incentiveTimeCheck(userAddress);
    }
    
    // Pre-register participants for lockup campaign, will be properly registered after user transfer tokens to contract
    // # params userAddr: address of registered user
    // # params wwbAmount: amount of token to lock (in wei)
    // # params months: address of registered user
    function preRegisterParticipant(address userAddr, uint256 months) public returns (bool) {
        require(firstSet == true, "LockupCampaign: rates data for WWB token not yet set for first time");
        require(userAddr != address(0), "LockupCampaign: user address is zero");
        require(months > 0, "LockupCampaign: months to lock is zero");
        
        _registParticipant(userAddr, months);
        return true;
    }
    
    // Requests additional tokens for users locked more than 6 months
    // # params user: address of registered user
    // # params token: address of participating token to request
    function requestExtraToken(address user, address token) public {
        require(isRegisteredParticipant(user), "LockupCampaign: User not registered.");
        require(tokenAddresses.length > 0, "LockupCampaign: no participating token data is entered yet");
        require(userList[user].month >= 6, "LockupCampaign: user must lock more than 6 months to request extra token");
        
        _requestExtraTokens(user, token);
    }
    
    // Releases the token and respective additional tokens to user after lock period passed
    // # params user: address of registered user
    function releaseParticipantTokens(address userAddr) public returns (bool){
        require(isRegisteredParticipant(userAddr), "LockupCampaign: User not registered.");
        require(_incentiveTimeCheck(userAddr));
        require(userList[userAddr].status != LockStatus.LOCKED, "LockupCampaign: Token lock period still ongoing.");
        require(userList[userAddr].status != LockStatus.RELEASED, "LockupCampaign: Token already released.");
        
        _releaseWwbTokens(userAddr);
        
        if(extraList[userAddr].exTokenAddress.length != 0){
            _releaseOtherTokens(userAddr);
        }
        
        return true;
    }
    
    // --------------- extra functions ---------------
    
    // Returns string converted bytes value
    // # params str: a string value to convert
    // * returns (bytes): converted string in bytes value
    function convertStrToBytes(string memory str) public pure returns (bytes memory){
        return bytes(str);
    }
    
    // --------------- internal functions ---------------
    
    function _setWwbRate(uint256 i3, uint256 i6, uint256 i9) internal {
        wwbInfo.incentive3 = i3;
        wwbInfo.incentive6 = i6;
        wwbInfo.incentive9 = i9;
        firstSet = true;
    }
    
    function _registParticipant(address addr, uint256 month) internal {
        ParticipatingUsers memory user = ParticipatingUsers(0, month, 0, false, LockStatus.NULL);
        userList[addr] = user;
        
        emit PreRegister(addr);
    }
    
    function _confirmRegister(address addr, uint256 val) internal {
        uint256 finalDate = now.addMonths(userList[addr].month);
        userList[addr].amountWWB = val;
        userList[addr].lockEnd = finalDate;
        userList[addr].status = LockStatus.LOCKED;
        
        wwbInfo.totalLocked = wwbInfo.totalLocked.add(val);
        wwbInfo.currentLocked = wwbInfo.currentLocked.add(val);
        
        emit ConfirmRegister(addr, now, finalDate);
    }
    
    function _getLockStatus(LockStatus stat) internal pure returns (bool) {
        if (stat == LockStatus.LOCKED || stat == LockStatus.NULL){
            return false;
        } else {
            return true;
        }
    }
    
    // Updates the status and send user incentives given to lockup
    function _incentiveTimeCheck(address user) internal returns (bool) {
        if (now >= userList[user].lockEnd){
            if (userList[user].status == LockStatus.LOCKED && userList[user].incCalculated != true) {
                uint256 val = _calcIncentives(user);
                if (extraList[user].exTokenAddress.length != 0) { _calcExtra(user, val); }
                userList[user].status = LockStatus.UNLOCKED;
                userList[user].incCalculated = true;
                
                emit TokenUnlocked(user, now);
            }
        }
        return true;
    }
    
    // Incentives calculation
    function _calcIncentives(address user) internal returns (uint256){
        uint256 m = userList[user].month;
        uint256 added;
        if (m >= 3 && m < 6){
            added = _calcAdd(userList[user].amountWWB, wwbInfo.incentive3);
        } else if (m >= 6 && m < 12){
            added = _calcAdd(userList[user].amountWWB, wwbInfo.incentive6);
        } else if (m >= 12) {
            added = _calcAdd(userList[user].amountWWB, wwbInfo.incentive9);
        }
        userList[user].amountWWB = userList[user].amountWWB.add(added);
        wwbInfo.totalExtraGiven = wwbInfo.totalExtraGiven.add(added);
        wwbInfo.currentLocked = wwbInfo.currentLocked.add(added);
        
        return added;
    }
    
    function _calcExtra(address user, uint256 added) internal {
        for (uint i = 0; i < extraList[user].exTokenAddress.length; i++){
            uint8 dec = extraList[user].exTokenDecimals[i];
            uint256 total;
                
            if (dec > 6) { total = added.mul((10 ** uint256(dec - 6))); }
            else if (dec < 6) { total = added.div((10 ** uint256(6 - dec))); }
                
            extraList[user].exTokenAmount.push(total);
        }
    }

    // rate calc
    function _calcAdd(uint256 total, uint256 rate) internal pure returns (uint256){
        uint256 r = total.mul(rate);
        r = r.div(10000);
        return r;
    }
    
    function _requestExtraTokens(address user, address token) internal {
        require(isParticipatingTokens(token), "LockupCampaign: token address is not participating token");
        //extraList[user].exTokenAddress.push(token);
        
        for (uint i = 0; i < tokenAddresses.length; i++){
            if(token == tokenAddresses[i]){
                extraList[user].exTokenAddress.push(token);
                extraList[user].exTokenDecimals.push(tokenDecimals[i]);
                break;
            }
        }

        emit EtcTokenRequested(user, token);
    }
    
    function _releaseWwbTokens(address user) internal {
        uint256 amt = userList[user].amountWWB;
        ERC20Interface(wwbAddress).transfer(user, amt);
        wwbInfo.currentLocked = wwbInfo.currentLocked.sub(amt);
        userList[user].status = LockStatus.RELEASED;

        emit TokenReleased(user, amt);
    }
    
    function _releaseOtherTokens(address user) internal {
        for (uint i = 0; i < extraList[user].exTokenAddress.length; i++){
            address addr =  extraList[user].exTokenAddress[i];
            uint amt = extraList[user].exTokenAmount[i];
            
            ERC20Interface(addr).transfer(user, amt);
            
            emit EtcTokenReleased(user, addr, amt);
        }
    }
}
