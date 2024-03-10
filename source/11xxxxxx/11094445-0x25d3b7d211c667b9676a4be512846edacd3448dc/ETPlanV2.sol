pragma solidity >=0.4.23 <0.6.0;

import "./ETPlanToken.sol";
import "./ETPlan.sol";

contract ETPlanV2 {

    struct User {
        uint id;
        address referrer;
        uint partnersCount;

        mapping(uint8 => bool) activeQ8Levels;
        mapping(uint8 => bool) blocked;
        mapping(uint8 => uint) income;
    }

    struct Q8 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint reinvestCount;
    }

    uint8 public constant LAST_LEVEL = 12;

    uint public lastUserId = 2;
    address public owner;
    address public pool;
    address public manager;
    address public eTPlanToken;

    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => Q8) public q8Matrix;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    event NewUserPlace(address indexed user, address indexed referrer, uint8 level, uint8 place);
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 level);
    event NewRound(address indexed user, address indexed referrer, uint8 level);

    address public super;

    address public _this;

    modifier OnlySuper {
        require(msg.sender == super);
        _;
    }

    constructor() public {
        levelPrice[1] = 0.1 ether;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }
        _this = address(this);
        super = msg.sender;
    }

    function initQ8(address _etplan) OnlySuper external {
        ETPlan etplan = ETPlan(address(uint160(_etplan)));
        for (uint8 j = 1; j <= 12; j++) {
            (address currentReferrer, address[] memory firstLevelReferrals
            , address[] memory secondLevelReferrals,
            uint reinvestCount) = etplan.getq8Matrix(j);
            q8Matrix[j].currentReferrer = currentReferrer;
            q8Matrix[j].firstLevelReferrals = firstLevelReferrals;
            q8Matrix[j].secondLevelReferrals = secondLevelReferrals;
            q8Matrix[j].reinvestCount = reinvestCount;
        }
    }

    function initData(address _etplan, uint start, uint end) OnlySuper external {

        ETPlan etplan = ETPlan(address(uint160(_etplan)));
        owner = etplan.owner();
        manager = etplan.manager();
        pool = etplan.pool();
        eTPlanToken = etplan.eTPlanToken();
        lastUserId = end + 1;

        for (uint i = start; i <= end; i++) {
            address currentUser = etplan.idToAddress(i);
            (uint id,address referrer,uint partnersCount) = etplan.users(currentUser);
            User memory user = User({
                id : id,
                referrer : referrer,
                partnersCount : partnersCount
                });
            users[currentUser] = user;

            for (uint8 j = 1; j <= 12; j++) {
                if (i == 3) {
                    users[currentUser].blocked[j] = true;
                    users[currentUser].activeQ8Levels[j] = false;
                } else {
                    bool active = etplan.activeQ8Levels(currentUser, j);
                    users[currentUser].activeQ8Levels[j] = active;
                    users[currentUser].income[j] = etplan.income(currentUser, j);
                }
            }

            idToAddress[i] = currentUser;
        }
    }

    function() external payable {
        if (msg.data.length == 0) {
            return registration(msg.sender, owner);
        }

        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 0.1 ether, "registration cost 0.1");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        User memory user = User({
            id : lastUserId,
            referrer : referrerAddress,
            partnersCount : 0
            });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].activeQ8Levels[1] = true;

        lastUserId++;

        users[referrerAddress].partnersCount++;

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);

        updateQ8Referrer(userAddress, referrerAddress, uint8(1));
        if (ETPlanToken(eTPlanToken).balanceOf(_this) >= (levelPrice[uint8(1)] * 3 / 2)) {
            ETPlanToken(eTPlanToken).transfer(userAddress, levelPrice[uint8(1)]);
            ETPlanToken(eTPlanToken).transfer(referrerAddress, levelPrice[uint8(1)] / 2);
        }

    }

    function buyNewLevel(uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(!users[msg.sender].activeQ8Levels[level], "level already activated");

        if (users[msg.sender].blocked[level - 1]) {
            users[msg.sender].blocked[level - 1] = false;
        }
        users[msg.sender].activeQ8Levels[level] = true;
        address freeReferrer = findFreeQ8Referrer(msg.sender, level);
        updateQ8Referrer(msg.sender, freeReferrer, level);
        emit NewRound(msg.sender, freeReferrer, level);
        if (ETPlanToken(eTPlanToken).balanceOf(_this) >= (levelPrice[level] * 3 / 2)) {
            ETPlanToken(eTPlanToken).transfer(msg.sender, levelPrice[level]);
            ETPlanToken(eTPlanToken).transfer(freeReferrer, levelPrice[level] / 2);
        }
    }

    function updateQ8Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeQ8Levels[level], "500. Referrer level is inactive");

        if ((users[referrerAddress].income[level] % (levelPrice[level] / 2)) >= 6) {
            if (!users[referrerAddress].activeQ8Levels[level + 1] && level != LAST_LEVEL) {
                users[referrerAddress].blocked[level] = true;
            }
        }
        if (q8Matrix[level].firstLevelReferrals.length < 2) {
            q8Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, level, uint8(q8Matrix[level].firstLevelReferrals.length));

            q8Matrix[level].currentReferrer = referrerAddress;
            if (referrerAddress == owner) {
                users[owner].income[level] += levelPrice[level];
                return sendETHDividends(referrerAddress, userAddress, level, levelPrice[level]);
            }

            uint poolAmount = levelPrice[level] * 20 / 100;
            if (!address(uint160(pool)).send(poolAmount)) {
                return address(uint160(pool)).transfer(address(this).balance);
            }
            uint managerAmount = levelPrice[level] * 30 / 100;
            if (!address(uint160(manager)).send(managerAmount)) {
                return address(uint160(manager)).transfer(address(this).balance);
            }
            address freeReferrer = findFreeQ8Referrer(userAddress, level);
            users[freeReferrer].income[level] += levelPrice[level] / 2;
            return sendETHDividends(freeReferrer, userAddress, level, levelPrice[level] / 2);
        }
        q8Matrix[level].secondLevelReferrals.push(userAddress);
        q8Matrix[level].currentReferrer = referrerAddress;
        emit NewUserPlace(userAddress, referrerAddress, level, uint8(q8Matrix[level].secondLevelReferrals.length + 2));

        if (q8Matrix[level].secondLevelReferrals.length == 1) {
            address freeReferrer = findFreeQ8Referrer(userAddress, level);
            users[freeReferrer].income[level] += levelPrice[level] / 2;
            sendETHDividends(freeReferrer, userAddress, level, levelPrice[level] / 2);
            uint poolAmount = levelPrice[level] * 20 / 100;
            if (!address(uint160(pool)).send(poolAmount)) {
                return address(uint160(pool)).transfer(address(this).balance);
            }
            address freeReferrerRe = findFreeQ8Referrer(freeReferrer, level);
            users[freeReferrerRe].income[level] += levelPrice[level] * 30 / 100;
            return sendETHDividends(freeReferrerRe, userAddress, level, levelPrice[level] * 30 / 100);
        }

        if (q8Matrix[level].secondLevelReferrals.length == 4) {//reinvest
            q8Matrix[level].reinvestCount++;

            q8Matrix[level].firstLevelReferrals = new address[](0);
            q8Matrix[level].secondLevelReferrals = new address[](0);
        }
        address freeReferrer = findFreeQ8Referrer(userAddress, level);
        users[freeReferrer].income[level] += levelPrice[level] / 2;
        sendETHDividends(freeReferrer, userAddress, level, levelPrice[level] / 2);
        uint poolAmount = levelPrice[level] * 20 / 100;
        if (!address(uint160(pool)).send(poolAmount)) {
            return address(uint160(pool)).transfer(address(this).balance);
        }
        uint managerAmount = levelPrice[level] * 30 / 100;
        if (!address(uint160(manager)).send(managerAmount)) {
            return address(uint160(manager)).transfer(address(this).balance);
        }
    }

    function findFreeQ8Referrer(address userAddress, uint8 level) public view returns (address) {
        while (true) {
            if (users[users[userAddress].referrer].activeQ8Levels[level]) {
                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function findEthReceiver(address userAddress, address _from, uint8 level) private returns (address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        while (true) {
            if (users[receiver].blocked[level]) {
                emit MissedEthReceive(receiver, _from, level);
                isExtraDividends = true;
                receiver = users[receiver].referrer;
            } else {
                return (receiver, isExtraDividends);
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 level, uint amount) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, level);

        if (!address(uint160(receiver)).send(amount)) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }

        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, level);
        }
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function activeQ8Levels(address _user, uint8 level) public view returns (bool){
        return users[_user].activeQ8Levels[level];
    }

    function blocked(address _user, uint8 level) public view returns (bool){
        return users[_user].blocked[level];
    }

    function income(address _user, uint8 level) public view returns (uint){
        return users[_user].income[level];
    }
    function getq8Matrix(uint8 level) public view returns (address, address[] memory, address[] memory, uint){
        return (q8Matrix[level].currentReferrer,
        q8Matrix[level].firstLevelReferrals,
        q8Matrix[level].secondLevelReferrals,
        q8Matrix[level].reinvestCount);
    }

    function updatePool(address _pool) public OnlySuper {
        pool = _pool;
    }

    function updateManager(address _manager) public OnlySuper {
        manager = _manager;
    }

    function updateSuper(address _super) public OnlySuper {
        super = _super;
    }

    function update(address _user, uint8 _level) public OnlySuper {
        require(isUserExists(_user), "user not exists");
        users[_user].activeQ8Levels[_level] = !users[_user].activeQ8Levels[_level];
    }

    function updateBlocked(address _user, uint8 _level) public OnlySuper {
        require(isUserExists(_user), "user not exists");
        users[_user].blocked[_level] = !users[_user].blocked[_level];
    }

    function withdrawELS(address _user, uint _value) public OnlySuper {
        ETPlanToken(eTPlanToken).transfer(_user, _value);
    }
}

