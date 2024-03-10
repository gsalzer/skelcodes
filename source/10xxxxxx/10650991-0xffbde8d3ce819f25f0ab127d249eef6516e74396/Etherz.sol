pragma solidity 0.5.14;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract ERC20 {
    function mint(address reciever, uint256 value) public returns(bool);
}

contract Etherz {

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint currentLevel;
        uint totalEarningEth;
        mapping(uint => address[]) referral;
        mapping(uint => uint) levelExpired;
    }
    
    struct AutoPoolUserStruct {
        bool isExist;
        address UserAddress;
        uint uniqueId;
        uint referrerID;
        mapping(uint => uint[]) firstLineRef;
        mapping(uint => uint[]) secondLineRef;
        uint currentLevel;
        uint totalEarningEth;
        mapping(uint => bool) levelStatus;
        mapping(uint =>uint) reInvestCount;
    }
    
    using SafeMath for uint256;
    address public ownerAddress; 
    bool public lockStatus;
    uint public adminFee = 16 ether;
    uint public workPlancurrentId = 0;
    uint public autoPooluniqueId = 0;
    uint workPlanRefLimit = 2;
    uint public PERIOD_LENGTH = 180 days;
    uint public WorkplanToken = 100 ether;
    uint public AutopoolToken = 100 ether;
    ERC20 Token;
    
    mapping (uint => uint) public WorkPlanLevelPrice;
    mapping (address => uint) public currentTree;
    mapping (uint => uint) public AutoPoolLevelPrice;
   
    mapping (address => UserStruct) public users;
    mapping (uint => AutoPoolUserStruct) public autoPoolUniqueUsers;
    mapping (uint => mapping (uint => AutoPoolUserStruct)) public autoPoolUsers;
    
    mapping (uint => address) public userList;
    mapping (uint => address) public autoPoolUniqueUserList;
    mapping (address => uint) public apAddressToId;
    mapping (uint => mapping (uint => address)) public autoPoolUserList;
    
    mapping (address => mapping (uint => mapping (uint => uint))) public EarnedEth;
    mapping (address => uint) public loopCheck; 
    mapping (uint => uint) public autoPoolcurrentId;
    
    event regLevelEvent(uint indexed Matrix, address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(uint indexed Matrix, address indexed UserAddress, uint Levelno, uint Time);
    event getMoneyForLevelEvent(uint indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);
    event lostMoneyForLevelEvent(uint indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);
    
    constructor(address _tokenAddress) public {
        ownerAddress = msg.sender;
        Token = ERC20(_tokenAddress);
        
        // WorkPlanLevelPrice
        WorkPlanLevelPrice[1] = 0.03 ether;
        WorkPlanLevelPrice[2] = 0.05 ether;
        WorkPlanLevelPrice[3] = 0.08 ether;
        WorkPlanLevelPrice[4] = 0.23 ether;
        WorkPlanLevelPrice[5] = 0.84 ether;
        WorkPlanLevelPrice[6] = 1 ether;
        WorkPlanLevelPrice[7] = 2 ether;
        WorkPlanLevelPrice[8] = 4 ether;
        WorkPlanLevelPrice[9] = 8 ether;
        WorkPlanLevelPrice[10] = 16 ether;
        WorkPlanLevelPrice[11] = 32 ether;
        WorkPlanLevelPrice[12] = 64 ether;
        WorkPlanLevelPrice[13] = 128 ether;
        WorkPlanLevelPrice[14] = 256 ether;
        WorkPlanLevelPrice[15] = 512 ether;
        WorkPlanLevelPrice[16] = 1024 ether;
        
        // NonWorkPlanLevelPrice
        AutoPoolLevelPrice[1] = 0.02 ether;
        AutoPoolLevelPrice[2] = 0.06 ether;
        AutoPoolLevelPrice[3] = 0.18 ether;
        AutoPoolLevelPrice[4] = 0.54 ether;
        AutoPoolLevelPrice[5] = 1.62 ether;
        AutoPoolLevelPrice[6] = 4.86 ether;
        AutoPoolLevelPrice[7] = 14.58 ether;
        AutoPoolLevelPrice[8] = 43.74 ether;
        AutoPoolLevelPrice[9] = 131.22 ether;
        AutoPoolLevelPrice[10] = 393.66 ether;
        AutoPoolLevelPrice[11] = 1180.98 ether;
        AutoPoolLevelPrice[12] = 3542.94 ether;
        AutoPoolLevelPrice[13] = 10628.82 ether;
        AutoPoolLevelPrice[14] = 31886.46 ether;
        AutoPoolLevelPrice[15] = 95659.38 ether;
        AutoPoolLevelPrice[16] = 286978.14 ether;
        
        
        UserStruct memory userStruct;
        workPlancurrentId = workPlancurrentId.add(1);

        userStruct = UserStruct({
            isExist: true,
            id: workPlancurrentId,
            referrerID: 0,
            currentLevel:1,
            totalEarningEth:0
        });
        users[ownerAddress] = userStruct;
        userList[workPlancurrentId] = ownerAddress;
        
        AutoPoolUserStruct memory autoPoolStruct;
        autoPooluniqueId = autoPooluniqueId.add(1);
        
        autoPoolStruct = AutoPoolUserStruct({
            isExist: true,
            UserAddress: ownerAddress,
            uniqueId: autoPooluniqueId,
            referrerID: 0,
            currentLevel: 1,
            totalEarningEth:0
        });        
        autoPoolUniqueUsers[autoPooluniqueId] = autoPoolStruct;
        autoPoolUniqueUserList[autoPooluniqueId] = ownerAddress;
        apAddressToId[ownerAddress] = autoPooluniqueId;
        
         for(uint i = 1; i <= 16; i++) {
            users[ownerAddress].currentLevel = i;
            users[ownerAddress].levelExpired[i] = 55555555555;
            autoPoolcurrentId[i] = autoPoolcurrentId[i].add(1);
            autoPoolUsers[i][autoPoolcurrentId[i]].levelStatus[i] = true;
            autoPoolUserList[i][autoPoolcurrentId[i]] = ownerAddress;
            autoPoolUsers[i][autoPoolcurrentId[i]] = autoPoolStruct;
            autoPoolUniqueUsers[autoPooluniqueId].currentLevel = i;
            autoPoolUniqueUsers[autoPooluniqueId].levelStatus[i] = true;
            
        }
    }
    
    //fallback
    function () external payable {
        revert("Invalid Transaction");
    }
    
    function workPlanregisteration(uint _referrerID) external payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist == false, "User exist");
        require(_referrerID > 0 && _referrerID <= workPlancurrentId, "Incorrect referrer Id");
        require(msg.value == WorkPlanLevelPrice[1], "Incorrect Value");
        address referer = userList[_referrerID];
        
        if(users[referer].referral[currentTree[referer]].length >= workPlanRefLimit)
            currentTree[referer] = currentTree[referer].add(1);
        
        UserStruct memory userStruct;
        workPlancurrentId++;
        
        userStruct = UserStruct({
            isExist: true,
            id: workPlancurrentId,
            referrerID: _referrerID,
            currentLevel: 1,
            totalEarningEth:0
        });

        users[msg.sender] = userStruct;
        userList[workPlancurrentId] = msg.sender;
        users[msg.sender].levelExpired[1] = now.add(PERIOD_LENGTH);
        users[referer].referral[currentTree[referer]].push(msg.sender);
        loopCheck[msg.sender] = 0;

        workPlanPay(0,1, msg.sender,((WorkPlanLevelPrice[1].mul(adminFee)).div(10**20)), msg.value);

        emit regLevelEvent(1,msg.sender, userList[_referrerID], now);
    }
    
    function autoPoolregistration() external payable {
        uint _userId = apAddressToId[msg.sender];  
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist == true, "User not exist in working plan");
        require(autoPoolUniqueUsers[_userId].isExist ==  false, "User Exist");
        require(msg.value == AutoPoolLevelPrice[1], "Incorrect Value");
        
        uint IReferrer;
        uint _referrerID;
        
        for(uint i=1;i <= autoPoolcurrentId[1]; i++) {
            if(autoPoolUsers[1][i].secondLineRef[1].length < 9) {
                (_referrerID,IReferrer) = findAPReferrer(1,i); 
                break;
            }
            else if(autoPoolUsers[1][i].secondLineRef[1].length == 9) {
                continue;
            }
        }
        
        AutoPoolUserStruct memory nonWorkUserStruct;
        autoPoolcurrentId[1] = autoPoolcurrentId[1].add(1);
        autoPooluniqueId++;
        
        nonWorkUserStruct = AutoPoolUserStruct({
            isExist: true,
            UserAddress: msg.sender,
            uniqueId: autoPooluniqueId,
            referrerID: IReferrer,
            currentLevel: 1,
            totalEarningEth:0
        });

        autoPoolUsers[1][autoPoolcurrentId[1]] = nonWorkUserStruct;
        autoPoolUserList[1][autoPoolcurrentId[1]] = msg.sender;
        autoPoolUsers[1][autoPoolcurrentId[1]].levelStatus[1] = true;
        autoPoolUsers[1][autoPoolcurrentId[1]].reInvestCount[1] = 0;
        
        autoPoolUniqueUsers[autoPooluniqueId] = nonWorkUserStruct;
        autoPoolUniqueUserList[autoPooluniqueId] = msg.sender;
        apAddressToId[msg.sender] = autoPooluniqueId;
        autoPoolUniqueUsers[autoPooluniqueId].levelStatus[1] = true;
        autoPoolUniqueUsers[autoPooluniqueId].reInvestCount[1] = 0;
        
        autoPoolUsers[1][IReferrer].firstLineRef[1].push(autoPoolcurrentId[1]);
        autoPoolUniqueUsers[apAddressToId[autoPoolUsers[1][IReferrer].UserAddress]].firstLineRef[1].push(autoPooluniqueId);
        
        if(_referrerID != 0) {
            autoPoolUsers[1][_referrerID].secondLineRef[1].push(autoPoolcurrentId[1]);
            autoPoolUniqueUsers[apAddressToId[autoPoolUsers[1][_referrerID].UserAddress]].secondLineRef[1].push(autoPooluniqueId);
        }
        if(_referrerID == 0)
            _referrerID = 1;
        
        autoPoolUsers[1][autoPoolcurrentId[1]].firstLineRef[1] = new uint[](0);
        autoPoolUsers[1][autoPoolcurrentId[1]].secondLineRef[1] = new uint[](0);
        
        autoPoolUniqueUsers[autoPooluniqueId].firstLineRef[1] = new uint[](0);
        autoPoolUniqueUsers[autoPooluniqueId].secondLineRef[1] = new uint[](0);
        
        if(autoPoolUsers[1][_referrerID].secondLineRef[1].length == 9) {
            autoPoolPay(0, 1, _referrerID , ((AutoPoolLevelPrice[1].mul(adminFee)).div(10**20)), msg.value);
            reInvest(_referrerID,1);
            autoPoolUniqueUsers[apAddressToId[autoPoolUsers[1][_referrerID].UserAddress]].secondLineRef[1] = new uint[](0);
            autoPoolUniqueUsers[apAddressToId[autoPoolUsers[1][_referrerID].UserAddress]].firstLineRef[1] = new uint[](0);
            autoPoolUsers[1][_referrerID].reInvestCount[1] =  autoPoolUsers[1][_referrerID].reInvestCount[1].add(1);
            autoPoolUniqueUsers[_referrerID].reInvestCount[1] =  autoPoolUniqueUsers[_referrerID].reInvestCount[1].add(1);
        }
        else if(autoPoolUsers[1][_referrerID].secondLineRef[1].length < 9) {
            autoPoolPay(0, 1, autoPoolcurrentId[1], ((AutoPoolLevelPrice[1].mul(adminFee)).div(10**20)), msg.value);
        }
        
        emit regLevelEvent(2, msg.sender, autoPoolUserList[1][_referrerID], now);
    }
    
    function workPlanbuyLevel(uint256 _level) external payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist, "User not exist"); 
        require(_level > 0 && _level <= 16, "Incorrect level");
        require(msg.value == WorkPlanLevelPrice[_level], "Incorrect Value");
            
        for(uint l =_level - 1; l > 0; l--) 
            require(users[msg.sender].levelExpired[l] > now, "Buy the previous level");
       
        if(users[msg.sender].levelExpired[_level] == 0) {
            users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            users[msg.sender].currentLevel = _level;
        }else 
            users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
       
       loopCheck[msg.sender] = 0;
       
       workPlanPay(0,_level, msg.sender,((WorkPlanLevelPrice[_level].mul(adminFee)).div(10**20)),msg.value);

       emit buyLevelEvent(1,msg.sender, _level, now);
    }
    
    function autoPoolbuyLevel(uint256 _level) external payable {
        uint _userId = apAddressToId[msg.sender];
        require(lockStatus == false, "Contract Locked");
        require(_level > 0 && _level <= 16, "Incorrect level");
        require(autoPoolUniqueUsers[_userId].isExist ==  true, "User not exist");
        require(autoPoolUniqueUsers[_userId].levelStatus[_level] == false, "Already Active in this level");
        require(msg.value == AutoPoolLevelPrice[_level], "Incorrect Value");
            
        for(uint l =_level - 1; l > 0; l--) 
            require(users[msg.sender].levelExpired[_level] > now && autoPoolUniqueUsers[_userId].levelStatus[l] == true, "Buy the previous level");
        
        uint firstLineId;
        uint secondLineId;
        
        for(uint i=1;i <= autoPoolcurrentId[_level]; i++) {
            
            if(autoPoolUsers[_level][i].secondLineRef[_level].length < 9) {
                (secondLineId,firstLineId) = findAPReferrer(_level,i); 
                break;
            }
            else if(autoPoolUsers[_level][i].secondLineRef[_level].length == 9) {
                continue;
            }
        } 
        
        AutoPoolUserStruct memory nonWorkUserStruct;
        autoPoolcurrentId[_level] = autoPoolcurrentId[_level].add(1);
        
        nonWorkUserStruct = AutoPoolUserStruct({
            isExist: true,
            UserAddress: msg.sender,
            uniqueId: autoPooluniqueId,
            referrerID: firstLineId,
            currentLevel: _level,
            totalEarningEth:0
            });
            
        autoPoolUsers[_level][autoPoolcurrentId[_level]] = nonWorkUserStruct;
        autoPoolUserList[_level][autoPoolcurrentId[_level]] = msg.sender;
        autoPoolUsers[_level][autoPoolcurrentId[_level]].levelStatus[_level] = true;
        autoPoolUsers[_level][autoPoolcurrentId[_level]].reInvestCount[_level] = 0;
        
        autoPoolUniqueUsers[_userId].levelStatus[_level] = true;
        autoPoolUniqueUsers[_userId].currentLevel = _level;
        autoPoolUniqueUsers[_userId].firstLineRef[_level] = new uint[](0);
        autoPoolUniqueUsers[_userId].secondLineRef[_level] = new uint[](0);
        autoPoolUniqueUsers[_userId].reInvestCount[_level] = 0;
        
        autoPoolUsers[_level][firstLineId].firstLineRef[_level].push(autoPoolcurrentId[_level]);
        autoPoolUniqueUsers[apAddressToId[autoPoolUsers[_level][firstLineId].UserAddress]].firstLineRef[_level].push(apAddressToId[autoPoolUsers[_level][autoPoolcurrentId[_level]].UserAddress]);
        
        if(secondLineId != 0) {
            autoPoolUsers[_level][secondLineId].secondLineRef[_level].push(autoPoolcurrentId[_level]);
            autoPoolUniqueUsers[apAddressToId[autoPoolUsers[_level][secondLineId].UserAddress]].secondLineRef[_level].push(apAddressToId[autoPoolUsers[_level][autoPoolcurrentId[_level]].UserAddress]);
        }
        if(secondLineId == 0)
            secondLineId = 1;
        
        autoPoolUsers[_level][autoPoolcurrentId[_level]].firstLineRef[_level] = new uint[](0);
        autoPoolUsers[_level][autoPoolcurrentId[_level]].secondLineRef[_level] = new uint[](0);
        
        autoPoolUniqueUsers[_userId].firstLineRef[_level] = new uint[](0);
        autoPoolUniqueUsers[_userId].secondLineRef[_level] = new uint[](0);
        
        if(autoPoolUsers[_level][secondLineId].secondLineRef[_level].length == 9) {
            autoPoolPay(0,_level,secondLineId ,((AutoPoolLevelPrice[_level].mul(adminFee)).div(10**20)), msg.value);
            reInvest(secondLineId,_level);
            autoPoolUniqueUsers[apAddressToId[autoPoolUsers[_level][secondLineId].UserAddress]].secondLineRef[_level] = new uint[](0);
            autoPoolUniqueUsers[apAddressToId[autoPoolUsers[_level][secondLineId].UserAddress]].firstLineRef[_level] = new uint[](0);
            autoPoolUsers[_level][secondLineId].reInvestCount[_level] =  autoPoolUsers[_level][secondLineId].reInvestCount[_level].add(1);
            autoPoolUniqueUsers[secondLineId].reInvestCount[_level] =  autoPoolUniqueUsers[secondLineId].reInvestCount[_level].add(1);
        }
        else if(autoPoolUsers[_level][secondLineId].secondLineRef[_level].length < 9) {
            autoPoolPay(0,_level,autoPoolcurrentId[_level],((AutoPoolLevelPrice[_level].mul(adminFee)).div(10**20)), msg.value);
        }
        emit buyLevelEvent(2,msg.sender, _level, now);
    }
    
    function contractLock(bool _lockStatus) public returns(bool) {
        require(msg.sender == ownerAddress, "Invalid User");
        lockStatus = _lockStatus;
        return true;
    }
    
    function updateAdminFeePercentage(uint256 _adminFee) public returns(bool) {
        require(msg.sender == ownerAddress, "Only Owner");
        adminFee = _adminFee;
        return true;  
    }
    
    function updateWorkPlanLevelPrice(uint _level, uint _price) public returns(bool) {
          require(msg.sender == ownerAddress, "Only Owner");
          WorkPlanLevelPrice[_level] = _price;
          return true;
    }
    
    function updateAutoPoolLevelPrice(uint _level, uint _price) public returns(bool) {
        require(msg.sender == ownerAddress, "Only Owner");
        AutoPoolLevelPrice[_level] = _price;
        return true;
    }

    function updateWorkPlanToken(uint _token) public returns (bool) {
        require(msg.sender == ownerAddress, "only Owner");
        WorkplanToken = _token;
        return true;
    }
    
    function updateAutoPoolToken(uint _token) public returns (bool) {
        require(msg.sender == ownerAddress, "Only Owner");
        AutopoolToken = _token;
        return true;
    }
    
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerAddress, "Only Owner");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
    
    function findAPReferrer(uint _level,uint _refId) internal view returns(uint,uint) {
        
        if(autoPoolUsers[_level][_refId].firstLineRef[_level].length <3)
            return(autoPoolUsers[_level][_refId].referrerID,_refId);
            
        else {
            uint[] memory referrals = new uint[](3);
            referrals[0] = autoPoolUsers[_level][_refId].firstLineRef[_level][0];
            referrals[1] = autoPoolUsers[_level][_refId].firstLineRef[_level][1];
            referrals[2] = autoPoolUsers[_level][_refId].firstLineRef[_level][2];
            
            if(autoPoolUsers[_level][_refId].secondLineRef[_level].length == 0 ||
            autoPoolUsers[_level][_refId].secondLineRef[_level].length == 3 ||
            autoPoolUsers[_level][_refId].secondLineRef[_level].length == 6) {
                if(autoPoolUsers[_level][referrals[0]].firstLineRef[_level].length < 3) {
                    return (_refId, referrals[0]);
                }
            }
            
            else if(autoPoolUsers[_level][_refId].secondLineRef[_level].length == 1 ||
            autoPoolUsers[_level][_refId].secondLineRef[_level].length == 4 ||
            autoPoolUsers[_level][_refId].secondLineRef[_level].length == 7) {
                if(autoPoolUsers[_level][referrals[1]].firstLineRef[_level].length < 3) {
                    return (_refId, referrals[1]);
                }
            }
            
            else if(autoPoolUsers[_level][_refId].secondLineRef[_level].length == 2 ||
            autoPoolUsers[_level][_refId].secondLineRef[_level].length == 5 ||
            autoPoolUsers[_level][_refId].secondLineRef[_level].length == 8) {
                if(autoPoolUsers[_level][referrals[2]].firstLineRef[_level].length < 3) {
                    return (_refId, referrals[2]);
                }
            }
        }
    }
    
    function viewWPUserReferral(address _userAddress,uint _tree) public view returns(address[] memory) {
        return users[_userAddress].referral[_tree];
    }
    
    function viewAPUserReferral(uint _userId, uint _level) public view returns(uint[] memory, uint[] memory) {
        return (autoPoolUniqueUsers[_userId].firstLineRef[_level],autoPoolUniqueUsers[_userId].secondLineRef[_level]);
    }
    
    function viewWPUserLevelExpired(address _userAddress,uint _level) public view returns(uint) {
        return users[_userAddress].levelExpired[_level];
    }
    
    function viewAPUserLevelExpired(uint _userId,uint _level) public view returns(bool) {
        return autoPoolUniqueUsers[_userId].levelStatus[_level];
    }
    
    function viewAPUserReInvestCount(uint _userId, uint _level) public view returns(uint) {
        return autoPoolUniqueUsers[_userId].reInvestCount[_level];
    }
   
    function getWorkPlanTotalEarnedEther() public view returns(uint) {
        uint totalEth;
        
        for( uint i=1;i<=workPlancurrentId;i++) {
            totalEth = totalEth.add(users[userList[i]].totalEarningEth);
        }
        
        return totalEth;
    }
    
    function getAutoPoolTotalEarnedEther() public view returns(uint) {
        uint totalEth;
        
        for( uint i = 1; i <= autoPooluniqueId; i++) {
            totalEth = totalEth.add(autoPoolUniqueUsers[i].totalEarningEth);
        }
        
        return totalEth;
    }
    
    function reInvest(uint _refId, uint _level) internal  returns(bool) {
        
        uint _IRef;
        uint _SRef;
        
        for(uint i = 1; i <= autoPoolcurrentId[_level]; i++) {
            
            if(autoPoolUsers[_level][i].secondLineRef[_level].length < 9) {
                (_SRef,_IRef) = findAPReferrer(_level,i); 
                break;
            }
            else if(autoPoolUsers[_level][i].secondLineRef[_level].length == 9) {
                continue;
            }
        }

        AutoPoolUserStruct memory nonWorkUserStruct;
        autoPoolcurrentId[_level]++;
        
        nonWorkUserStruct = AutoPoolUserStruct({
            isExist: true,
            UserAddress: autoPoolUserList[_level][_refId],
            uniqueId: autoPoolUsers[_level][_refId].uniqueId,
            referrerID: _IRef,
            currentLevel: _level,
            totalEarningEth:0
        });
            
        autoPoolUsers[_level][autoPoolcurrentId[_level]] = nonWorkUserStruct;
        autoPoolUserList[_level][autoPoolcurrentId[_level]] = msg.sender;
        autoPoolUsers[_level][autoPoolcurrentId[_level]].levelStatus[_level] = true;
        autoPoolUsers[_level][autoPoolcurrentId[_level]].reInvestCount[_level] = 0;
        
        autoPoolUsers[_level][_IRef].firstLineRef[_level].push(autoPoolcurrentId[_level]);
        autoPoolUniqueUsers[apAddressToId[autoPoolUsers[_level][_IRef].UserAddress]].firstLineRef[_level].push(apAddressToId[autoPoolUsers[_level][autoPoolcurrentId[_level]].UserAddress]);
        
        if(_SRef != 0) {
            autoPoolUsers[_level][_SRef].secondLineRef[_level].push(autoPoolcurrentId[_level]);
            autoPoolUniqueUsers[apAddressToId[autoPoolUsers[_level][_SRef].UserAddress]].secondLineRef[_level].push(apAddressToId[autoPoolUsers[_level][autoPoolcurrentId[_level]].UserAddress]);
        }
        if(_SRef == 0)
            _SRef = 1;
        
        autoPoolUsers[_level][autoPoolcurrentId[_level]].firstLineRef[_level] = new uint[](0);
        autoPoolUsers[_level][autoPoolcurrentId[_level]].secondLineRef[_level] = new uint[](0);
        
        if(autoPoolUsers[_level][_SRef].secondLineRef[_level].length == 9) {
            reInvest(_SRef,_level);
            autoPoolUniqueUsers[apAddressToId[autoPoolUsers[_level][_SRef].UserAddress]].secondLineRef[_level] = new uint[](0);
            autoPoolUniqueUsers[apAddressToId[autoPoolUsers[_level][_SRef].UserAddress]].firstLineRef[_level] = new uint[](0);
            autoPoolUsers[_level][_SRef].reInvestCount[_level] =  autoPoolUsers[_level][_SRef].reInvestCount[_level].add(1);
            autoPoolUniqueUsers[_SRef].reInvestCount[_level] =  autoPoolUniqueUsers[_SRef].reInvestCount[_level].add(1);
            autoPoolUsers[_level][_SRef].reInvestCount[_level] =  autoPoolUsers[_level][_SRef].reInvestCount[_level].add(1);
        }
       
        return true;
    }
    
    function getReferrer(uint _level,address _user) internal returns (address) {
      if (_level == 0 || _user == address(0)) {
        return _user;
      }
      return getReferrer( _level - 1,userList[users[_user].referrerID]);
    }

    function workPlanPay(uint _flag,uint _level,address _userAddress,uint _adminPrice,uint256 _amt) internal {
        
        address referer;
        
        if(_flag == 0)
            referer = getReferrer(_level,_userAddress);
        
        else if(_flag == 1) 
             referer = userList[users[_userAddress].referrerID];

        if(!users[referer].isExist) 
            referer = userList[1];
        
        if(loopCheck[msg.sender] >= 12) 
            referer = userList[1];
        
        if(users[referer].levelExpired[_level] >= now) {
            uint tobeminted = WorkplanToken * _level;
            require((address(uint160(referer)).send(WorkPlanLevelPrice[_level].sub(_adminPrice))) && 
            (address(uint160(ownerAddress)).send(_adminPrice)) &&
            (Token.mint(msg.sender, tobeminted)), "Transaction Failure");
            users[referer].totalEarningEth = users[referer].totalEarningEth.add(WorkPlanLevelPrice[_level]);
            EarnedEth[referer][1][_level] =  EarnedEth[referer][1][_level].add(WorkPlanLevelPrice[_level]);
            emit getMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,referer,users[referer].id, _level, WorkPlanLevelPrice[_level],now);
        }
        
        else  {
            if(loopCheck[msg.sender] < 12) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
                emit lostMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,referer,users[referer].id, _level, WorkPlanLevelPrice[_level],now);
                workPlanPay(1,_level, referer,_adminPrice,_amt);
            }
        }
    }
    
    function autoPoolPay(uint _flag,uint _level,uint _userId,uint _adminPrice,uint256 _amt) internal {
        
        uint[2] memory referer;
        
        if(_flag == 0){
           referer[1] = autoPoolUsers[_level][_userId].referrerID;
           referer[0] = autoPoolUsers[_level][referer[1]].referrerID;
        }
        
        else if(_flag == 1) 
             referer[0] = autoPoolUsers[_level][_userId].referrerID;

        if(!autoPoolUsers[_level][referer[0]].isExist) 
            referer[0] = 1;
        
         if(autoPoolUsers[_level][referer[0]].levelStatus[_level] == true) {
            uint tobeminted = AutopoolToken;
            address refererAddress = autoPoolUserList[_level][referer[0]];
            require((address(uint160(refererAddress)).send(_amt.sub(_adminPrice))) &&
            address(uint160(ownerAddress)).send(_adminPrice) &&
            (Token.mint(msg.sender, tobeminted)), "Transaction Failure");
                
            autoPoolUsers[_level][referer[0]].totalEarningEth = autoPoolUsers[_level][referer[0]].totalEarningEth.add(_amt.sub(_adminPrice));
            autoPoolUniqueUsers[apAddressToId[refererAddress]].totalEarningEth = autoPoolUniqueUsers[apAddressToId[refererAddress]].totalEarningEth.add(_amt.sub(_adminPrice));
            EarnedEth[refererAddress][2][_level] =  EarnedEth[refererAddress][2][_level].add(_amt.sub(_adminPrice));
            autoPoolUsers[_level][1].totalEarningEth = autoPoolUsers[_level][1].totalEarningEth.add(_adminPrice);
            autoPoolUniqueUsers[apAddressToId[ownerAddress]].totalEarningEth = autoPoolUniqueUsers[apAddressToId[ownerAddress]].totalEarningEth.add(_amt.sub(_adminPrice));
            EarnedEth[ownerAddress][2][_level] =  EarnedEth[ownerAddress][2][_level].add(_adminPrice);
            emit getMoneyForLevelEvent(2,msg.sender,_userId,refererAddress,referer[0], _level, AutoPoolLevelPrice[_level],now);
        }
        
        else  {
                address refererAddress = autoPoolUserList[_level][referer[0]];
                emit lostMoneyForLevelEvent(2,msg.sender,_userId,refererAddress,referer[0], _level, AutoPoolLevelPrice[_level],now);
                autoPoolPay(1,_level, referer[0],_adminPrice,_amt);
            }
        }
}
