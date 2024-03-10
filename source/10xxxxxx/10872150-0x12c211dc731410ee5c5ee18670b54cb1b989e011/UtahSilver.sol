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

contract UtahSilver {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeG3Levels;
        mapping(uint8 => bool) activeG4Levels;
        mapping(uint8 => G3Manual) G3Matrix;
        mapping(uint8 => G4Auto) G4Matrix;
    }
    
    struct G3Manual {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct G4Auto {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }

    ERC20 Token;
    using SafeMath for uint256;
    bool public lockStatus;
    uint8 public constant LAST_LEVEL = 9;
    uint public lastUserId = 2;
    address public ownerAddress;
    
    mapping(uint8 => uint) public levelPrice;
    mapping(address => User) public users;
    mapping(uint => address) public userIds;
    
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress,"only Owner");
        _;
    }
    
    modifier isLock() {
        require(lockStatus == false,"Contract Locked");
        _;
    }
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint amount, uint time);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8  matrix, uint8 level, uint amount, uint time);
    event Upgrade(address indexed user, address indexed referrer, uint8 indexed matrix, uint8 level,uint amount, uint time);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 indexed matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed _from, uint8 indexed matrix, uint8 level,uint amount, uint time);
    event RecievedEth(address indexed receiver, address indexed _from, uint8 indexed matrix, uint8 level,uint amount, uint time);
    event SentExtraEthDividends(address indexed _from, address indexed receiver, uint8 indexed matrix, uint8 level,uint amount, uint time);
    
    constructor(address _owner,address _tokenAddress) public {
        require(_tokenAddress != address(0),"Invalid Token Address");
        
        levelPrice[1] = 0.02 ether;
        levelPrice[2] = 0.04 ether;
        levelPrice[3] = 0.08 ether;
        levelPrice[4] = 0.16 ether;
        levelPrice[5] = 0.32 ether;
        levelPrice[6] = 0.64 ether;
        levelPrice[7] = 1.28 ether;
        levelPrice[8] = 2.56 ether;
        levelPrice[9] = 6 ether;
        
        
        ownerAddress = _owner;
        Token = ERC20(_tokenAddress);
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        userIds[1] = ownerAddress;
       
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeG3Levels[i] = true;
            users[ownerAddress].activeG4Levels[i] = true;
        }
        
    }
    
    // external functions
    function() external payable {
        revert("Invalid Contract Transaction");
    }
    
    function registrationExt(address referrerAddress) isLock external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) isLock external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeG3Levels[level], "level already activated");
            if (users[msg.sender].G3Matrix[level-1].blocked) {
                users[msg.sender].G3Matrix[level-1].blocked = false;
            }
            address freeG3Referrer = findFreeG3Referrer(msg.sender, level);
            users[msg.sender].G3Matrix[level].currentReferrer = freeG3Referrer;
            users[msg.sender].activeG3Levels[level] = true;
            updateG3Referrer(msg.sender, freeG3Referrer, level);
            emit Upgrade(msg.sender, freeG3Referrer, 1, level, msg.value, now);
        } else {
            require(!users[msg.sender].activeG4Levels[level], "level already activated"); 
            if (users[msg.sender].G4Matrix[level-1].blocked) {
                users[msg.sender].G4Matrix[level-1].blocked = false;
            }
            address freeG4Referrer = findFreeG4Referrer(msg.sender, level);
            users[msg.sender].activeG4Levels[level] = true;
            updateG4Referrer(msg.sender, freeG4Referrer, level);
            emit Upgrade(msg.sender, freeG4Referrer, 2, level, msg.value, now);
        }
    }   
    
    // public functions
    function failSafe(address payable _toUser, uint _amount) onlyOwner public returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
    function contractLock(bool _lockStatus) onlyOwner public returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
    function findFreeG3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeG3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeG4Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeG4Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveG3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeG3Levels[level];
    }

    function usersActiveG4Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeG4Levels[level];
    }

    function usersG3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory,uint, bool) {
        return (users[userAddress].G3Matrix[level].currentReferrer,
                users[userAddress].G3Matrix[level].referrals,
                users[userAddress].G3Matrix[level].reinvestCount,
                users[userAddress].G3Matrix[level].blocked);
    }

    function usersG4Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address,uint) {
        return (users[userAddress].G4Matrix[level].currentReferrer,
                users[userAddress].G4Matrix[level].firstLevelReferrals,
                users[userAddress].G4Matrix[level].secondLevelReferrals,
                users[userAddress].G4Matrix[level].blocked,
                users[userAddress].G4Matrix[level].closedPart,
                users[userAddress].G4Matrix[level].reinvestCount);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    //private functions
    function registration(address userAddress, address referrerAddress) isLock private {
        require(msg.value == levelPrice[1].mul(2), "registration cost 0.05");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeG3Levels[1] = true; 
        users[userAddress].activeG4Levels[1] = true;
        
        userIds[lastUserId] = userAddress;
        lastUserId = lastUserId.add(1);
        users[referrerAddress].partnersCount = users[referrerAddress].partnersCount.add(1);

        address freeG3Referrer = findFreeG3Referrer(userAddress, 1);
        users[userAddress].G3Matrix[1].currentReferrer = freeG3Referrer;
        updateG3Referrer(userAddress, freeG3Referrer, 1);

        updateG4Referrer(userAddress, findFreeG4Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, msg.value, now);
    }
    
    function updateG3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].G3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].G3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].G3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].G3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeG3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].G3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != ownerAddress) {
            //check referrer active level
            address freeReferrerAddress = findFreeG3Referrer(referrerAddress, level);
            if (users[referrerAddress].G3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].G3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            users[referrerAddress].G3Matrix[level].reinvestCount = users[referrerAddress].G3Matrix[level].reinvestCount.add(1);
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level, levelPrice[level], now);
            updateG3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(ownerAddress, userAddress, 1, level);
            users[ownerAddress].G3Matrix[level].reinvestCount = users[ownerAddress].G3Matrix[level].reinvestCount.add(1);
            emit Reinvest(ownerAddress, address(0), userAddress, 1, level, levelPrice[level], now);
        }
    }

    function updateG4Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeG4Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].G4Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].G4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].G4Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].G4Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == ownerAddress) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].G4Matrix[level].currentReferrer;            
            users[ref].G4Matrix[level].secondLevelReferrals.push(userAddress); 
            uint len = users[ref].G4Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].G4Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].G4Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].G4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].G4Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].G4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].G4Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].G4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }
            return updateG4ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].G4Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].G4Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].G4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].G4Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].G4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].G4Matrix[level].closedPart)) {
                updateG4(userAddress, referrerAddress, level, true);
                return updateG4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].G4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].G4Matrix[level].closedPart) {
                updateG4(userAddress, referrerAddress, level, true);
                return updateG4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateG4(userAddress, referrerAddress, level, false);
                return updateG4ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].G4Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateG4(userAddress, referrerAddress, level, false);
            return updateG4ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].G4Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateG4(userAddress, referrerAddress, level, true);
            return updateG4ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].G4Matrix[level].firstLevelReferrals[0]].G4Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].G4Matrix[level].firstLevelReferrals[1]].G4Matrix[level].firstLevelReferrals.length) {
            updateG4(userAddress, referrerAddress, level, false);
        } else {
            updateG4(userAddress, referrerAddress, level, true);
        }
        
        updateG4ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateG4(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].G4Matrix[level].firstLevelReferrals[0]].G4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].G4Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].G4Matrix[level].firstLevelReferrals[0]].G4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].G4Matrix[level].firstLevelReferrals[0]].G4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].G4Matrix[level].currentReferrer = users[referrerAddress].G4Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].G4Matrix[level].firstLevelReferrals[1]].G4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].G4Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].G4Matrix[level].firstLevelReferrals[1]].G4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].G4Matrix[level].firstLevelReferrals[1]].G4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].G4Matrix[level].currentReferrer = users[referrerAddress].G4Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateG4ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].G4Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory G4 = users[users[referrerAddress].G4Matrix[level].currentReferrer].G4Matrix[level].firstLevelReferrals;
        
        if (G4.length == 2) {
            if (G4[0] == referrerAddress ||
                G4[1] == referrerAddress) {
                users[users[referrerAddress].G4Matrix[level].currentReferrer].G4Matrix[level].closedPart = referrerAddress;
            } else if (G4.length == 1) {
                if (G4[0] == referrerAddress) {
                    users[users[referrerAddress].G4Matrix[level].currentReferrer].G4Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        users[referrerAddress].G4Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].G4Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].G4Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeG4Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].G4Matrix[level].blocked = true;
        }

        users[referrerAddress].G4Matrix[level].reinvestCount = users[referrerAddress].G4Matrix[level].reinvestCount.add(1);
        
        if (referrerAddress != ownerAddress) {
            address freeReferrerAddress = findFreeG4Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level, levelPrice[level], now);
            updateG4Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(ownerAddress, address(0), userAddress, 2, level, levelPrice[level], now);
            sendETHDividends(ownerAddress, userAddress, 2, level);
        }
    }
    
    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].G3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level, levelPrice[level], now);
                    isExtraDividends = true;
                    receiver = users[receiver].G3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].G4Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level, levelPrice[level], now);
                    isExtraDividends = true;
                    receiver = users[receiver].G4Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
        uint256 tobeminted;
        
        tobeminted = 25 ether;
        
        require( (address(uint160(receiver)).send(levelPrice[level])) && 
            Token.mint(msg.sender, tobeminted),"Invalid Transaction");
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level, levelPrice[level], now);
        }
        else {
             emit RecievedEth(receiver, _from, matrix, level, levelPrice[level], now);
        }
    }
    
    
}
