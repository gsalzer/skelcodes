pragma solidity ^0.5.0;

import './SafeMath.sol';
import './String.sol';
import './Address.sol';
import './Context.sol';
import './HumanChsek.sol';
import './Whitelist.sol';
import './DBUtilli.sol';


/**
 * @title Utillibrary
 * @dev This integrates the basic functions.
 */
contract Utillibrary is Whitelist {
    //lib using list
	using SafeMath for *;

    //Loglist
    event TransferEvent(address indexed _from, address indexed _to, uint _value, uint time);

    //base param setting
    // uint internal ethWei = 1 ether;
    uint internal ethWei = 10 finney;//Test 0.01ether

    /**
     * @dev Transfer to designated user
     * @param userAddress user address
     * @param money transfer-out amount
     */
	function sendMoneyToUser(address payable userAddress, uint money)
        internal
    {
		if (money > 0) {
			userAddress.transfer(money);
		}
	}

    /**
     * @dev Check and correct transfer amount
     * @param sendMoney transfer-out amount
     * @return bool,amount
     */
	function isEnoughBalance(uint sendMoney)
        internal
        view
        returns (bool, uint)
    {
		if (sendMoney >= address(this).balance) {
			return (false, address(this).balance);
		} else {
			return (true, sendMoney);
		}
	}

    /**
     * @dev get UserLevel for the investment amount
     * @param value investment amount
     * @return UserLevel
     */
	function getLevel(uint value)
        public
        view
        returns (uint)
    {
		if (value >= ethWei.mul(1) && value <= ethWei.mul(5)) {
			return 1;
		}
		if (value >= ethWei.mul(6) && value <= ethWei.mul(10)) {
			return 2;
		}
		if (value >= ethWei.mul(11) && value <= ethWei.mul(15)) {
			return 3;
		}
		return 0;
	}

    /**
     * @dev get NodeLevel for the investment amount
     * @param value investment amount
     * @return NodeLevel
     */
	function getNodeLevel(uint value)
        public
        view
        returns (uint)
    {
		if (value >= ethWei.mul(1) && value <= ethWei.mul(5)) {
			return 1;
		}
		if (value >= ethWei.mul(6) && value <= ethWei.mul(10)) {
			return 2;
		}
		if (value >= ethWei.mul(11)) {
			return 3;
		}
		return 0;
	}

    /**
     * @dev get scale for the level
     * @param level level
     * @return scale
     */
	function getScaleByLevel(uint level)
        public
        pure
        returns (uint)
    {
		if (level == 1) {
			return 5;
		}
		if (level == 2) {
			return 7;
		}
		if (level == 3) {
			return 10;
		}
		return 0;
	}

    /**
     * @dev get recommend scal for the level and times
     * @param level level
     * @param times The layer number of recommended
     * @return recommend scale
     */
	function getRecommendScaleByLevelAndTim(uint level, uint times)
        public
        pure
        returns (uint)
    {
		if (level == 1 && times == 1) {
			return 50;
		}
		if (level == 2 && times == 1) {
			return 70;
		}
		if (level == 2 && times == 2) {
			return 50;
		}
		if (level == 3) {
			if (times == 1) {
				return 100;
			}
			if (times == 2) {
				return 70;
			}
			if (times == 3) {
				return 50;
			}
			if (times >= 4 && times <= 10) {
				return 10;
			}
			if (times >= 11 && times <= 20) {
				return 5;
			}
			if (times >= 21) {
				return 1;
			}
		}
		return 0;
	}

    /**
     * @dev get burn scal for the level
     * @param level level
     * @return burn scale
     */
	function getBurnScaleByLevel(uint level)
        public
        pure
        returns (uint)
    {
		if (level == 1) {
			return 3;
		}
		if (level == 2) {
			return 6;
		}
		if (level == 3) {
			return 10;
		}
		return 0;
	}

    /**
     * @dev Transfer to designated addr
     * Authorization Required
     * @param _addr transfer-out address
     * @param _val transfer-out amount
     */
    function sendMoneyToAddr(address _addr, uint _val)
        public
        payable
        onlyOwner
    {
        require(_addr != address(0), "not the zero address");
        address(uint160(_addr)).transfer(_val);
        emit TransferEvent(address(this), _addr, _val, now);
    }
}


contract HYPlay is Context, HumanChsek, Whitelist, DBUtilli, Utillibrary {
    //lib using list
	using SafeMath for *;
    using String for string;
    using Address for address;

    //struct
	struct User {
		uint id;
		address userAddress;
        uint lineAmount;//bonus calculation mode line
        uint freezeAmount;//invest lock
		uint freeAmount;//invest out unlock
        uint dayBonusAmount;//Daily bonus amount (static bonus)
        uint bonusAmount;//add up static bonus amonut (static bonus)
		uint inviteAmonut;//add up invite bonus amonut (dynamic bonus)
		uint level;//user level
		uint nodeLevel;//user node Level
		uint investTimes;//settlement bonus number
		uint rewardIndex;//user current index of award
		uint lastRwTime;//last settlement time
	}
	struct AwardData {
        uint time;//settlement bonus time
        uint staticAmount;//static bonus of reward amount
		uint oneInvAmount;//One layer of reward amount
		uint twoInvAmount;//Two layer reward amount
		uint threeInvAmount;//Three layer or more bonus amount
	}

    //Loglist
    event InvestEvent(address indexed _addr, string _code, string _rCode, uint _value, uint time);
    event WithdrawEvent(address indexed _addr, uint _value, uint time);

    //base param setting
	address payable private devAddr = address(0);//The special account
	address payable private foundationAddr = address(0);//Foundation address

    //start Time setting
    uint startTime = 0;
	uint canSetStartTime = 1;
	uint period = 1 days;

    //Bonus calculation mode (0 invested,!=0 line)
    uint lineStatus = 0;

    //Round setting
	uint rid = 1;
	mapping(uint => uint) roundInvestCount;//RoundID InvestCount Mapping
	mapping(uint => uint) roundInvestMoney;//RoundID InvestMoney Mapping
	mapping(uint => uint[]) lineArrayMapping;//RoundID UID[] Mapping
    //RoundID [address User Mapping] Mapping
	mapping(uint => mapping(address => User)) userRoundMapping;
    //RoundID [address [rewardIndex AwardData Mapping] Mapping] Mapping
	mapping(uint => mapping(address => mapping(uint => AwardData))) userAwardDataMapping;

    //limit setting
	uint bonuslimit = ethWei.mul(15);
	uint sendLimit = ethWei.mul(100);
	uint withdrawLimit = ethWei.mul(15);

    /**
     * @dev the content of contract is Beginning
     */
	constructor (address _dbAddr, address _devAddr, address _foundationAddr) public {
        db = IDB(_dbAddr);
        devAddr = address(_devAddr).toPayable();
        foundationAddr = address(_foundationAddr).toPayable();
	}

    /**
     * @dev deposit
     */
	function() external payable {
	}

    /**
     * @dev Set invest mode
     * @param line invest mode
     */
	function actUpdateLine(uint line)
        external
        onlyIfWhitelisted
    {
		lineStatus = line;
	}

    /**
     * @dev Set start time
     * @param time start time
     */
	function actSetStartTime(uint time)
        external
        onlyIfWhitelisted
    {
		require(canSetStartTime == 1, "verydangerous, limited!");
		require(time > now, "no, verydangerous");
		startTime = time;
		canSetStartTime = 0;
	}

    /**
     * @dev Set End Round
     */
	function actEndRound()
        external
        onlyIfWhitelisted
    {
		require(address(this).balance < ethWei.mul(1), "contract balance must be lower than 1 ether");
		rid++;
		startTime = now.add(period).div(1 days).mul(1 days);
		canSetStartTime = 1;
	}

    /**
     * @dev Set all limit
     * @param _bonuslimit bonus limit
     * @param _sendLimit send limit
     * @param _withdrawLimit withdraw limit
     */
	function actAllLimit(uint _bonuslimit, uint _sendLimit, uint _withdrawLimit)
        external
        onlyIfWhitelisted
    {
		require(_bonuslimit >= ethWei.mul(15) && _sendLimit >= ethWei.mul(100) && _withdrawLimit >= ethWei.mul(15), "invalid amount");
		bonuslimit = _bonuslimit;
		sendLimit = _sendLimit;
		withdrawLimit = _withdrawLimit;
	}

    /**
     * @dev Set user status
     * @param addr user address
     * @param status user status
     */
	function actUserStatus(address addr, uint status)
        external
        onlyIfWhitelisted
    {
		require(status == 0 || status == 1 || status == 2, "bad parameter status");
        _setUser(addr, status);
	}

    /**
     * @dev Calculation of contract bonus
     * @param start start the entry
     * @param end end the entry
     * @param isUID parameter is UID
     */
	function calculationBonus(uint start, uint end, uint isUID)
        external
        isHuman()
        onlyIfWhitelisted
    {
		for (uint i = start; i <= end; i++) {
			uint userId = 0;
			if (isUID == 0) {
				userId = lineArrayMapping[rid][i];
			} else {
				userId = i;
			}
			address userAddr = _getIndexMapping(userId);
			User storage user = userRoundMapping[rid][userAddr];
			if (user.freezeAmount == 0 && user.lineAmount >= ethWei.mul(1) && user.lineAmount <= ethWei.mul(15)) {
				user.freezeAmount = user.lineAmount;
				user.level = getLevel(user.freezeAmount);
				user.lineAmount = 0;
				sendFeeToDevAddr(user.freezeAmount);
				countBonus_All(user.userAddress);
			}
		}
	}

    /**
     * @dev settlement bonus
     * @param start start the entry
     * @param end end the entry
     */
	function settlement(uint start, uint end)
        external
        onlyIfWhitelisted
    {
		for (uint i = start; i <= end; i++) {
			address userAddr = _getIndexMapping(i);
			User storage user = userRoundMapping[rid][userAddr];

            uint[2] memory user_data;
            (user_data, , ) = _getUserInfo(userAddr);
            uint user_status = user_data[1];

			if (now.sub(user.lastRwTime) <= 12 hours) {
				continue;
			}
			user.lastRwTime = now;

			if (user_status == 1) {
                user.rewardIndex = user.rewardIndex.add(1);
				continue;
			}

            //static bonus
			uint bonusStatic = 0;
			if (user.id != 0 && user.freezeAmount >= ethWei.mul(1) && user.freezeAmount <= bonuslimit) {
				if (user.investTimes < 5) {
					bonusStatic = bonusStatic.add(user.dayBonusAmount);
					user.bonusAmount = user.bonusAmount.add(bonusStatic);
					user.investTimes = user.investTimes.add(1);
				} else {
					user.freeAmount = user.freeAmount.add(user.freezeAmount);
					user.freezeAmount = 0;
					user.dayBonusAmount = 0;
					user.level = 0;
				}
			}

            //dynamic bonus
			uint inviteSend = 0;
            if (user_status == 0) {
                inviteSend = getBonusAmount_Dynamic(userAddr, rid, 0, false);
            }

            //sent bonus amonut
			if (bonusStatic.add(inviteSend) <= sendLimit) {
				user.inviteAmonut = user.inviteAmonut.add(inviteSend);
				bool isEnough = false;
				uint resultMoney = 0;
				(isEnough, resultMoney) = isEnoughBalance(bonusStatic.add(inviteSend));
				if (resultMoney > 0) {
					uint foundationMoney = resultMoney.div(10);
					sendMoneyToUser(foundationAddr, foundationMoney);
					resultMoney = resultMoney.sub(foundationMoney);
					address payable sendAddr = address(uint160(userAddr));
					sendMoneyToUser(sendAddr, resultMoney);
				}
			}

            AwardData storage awData = userAwardDataMapping[rid][userAddr][user.rewardIndex];
            //Record static bonus
            awData.staticAmount = bonusStatic;
            //Record settlement bonus time
            awData.time = now;

            //user reward Index since the increase
            user.rewardIndex = user.rewardIndex.add(1);
		}
	}

    /**
     * @dev the invest withdraw of contract is Beginning
     */
    function withdraw()
        public
        isHuman()
    {
		require(isOpen(), "Contract no open");
		User storage user = userRoundMapping[rid][_msgSender()];
		require(user.id != 0, "user not exist");
		uint sendMoney = user.freeAmount + user.lineAmount;

		require(sendMoney > 0, "Incorrect sendMoney");

		bool isEnough = false;
		uint resultMoney = 0;

		(isEnough, resultMoney) = isEnoughBalance(sendMoney);

        require(resultMoney > 0, "not Enough Balance");

		if (resultMoney > 0 && resultMoney <= withdrawLimit) {
			user.freeAmount = 0;
			user.lineAmount = 0;
			user.nodeLevel = getNodeLevel(user.freezeAmount);
            sendMoneyToUser(_msgSender(), resultMoney);
		}

        emit WithdrawEvent(_msgSender(), resultMoney, now);
	}

    /**
     * @dev the invest of contract is Beginning
     * @param code user invite Code
     * @param rCode recommend code
     */
	function invest(string memory code, string memory rCode)
        public
        payable
        isHuman()
    {
		require(isOpen(), "Contract no open");
		require(_msgValue() >= ethWei.mul(1) && _msgValue() <= ethWei.mul(15), "between 1 and 15");
		require(_msgValue() == _msgValue().div(ethWei).mul(ethWei), "invalid msg value");

        uint[2] memory user_data;
        (user_data, , ) = _getUserInfo(_msgSender());
        uint user_id = user_data[0];

		if (user_id == 0) {
			_registerUser(_msgSender(), code, rCode);
            (user_data, , ) = _getUserInfo(_msgSender());
            user_id = user_data[0];
		}

		uint investAmout;
		uint lineAmount;
		if (isLine()) {
			lineAmount = _msgValue();
		} else {
			investAmout = _msgValue();
		}
		User storage user = userRoundMapping[rid][_msgSender()];
		if (user.id != 0) {
			require(user.freezeAmount.add(user.lineAmount) == 0, "only once invest");
		} else {
			user.id = user_id;
			user.userAddress = _msgSender();
		}
        user.freezeAmount = investAmout;
        user.lineAmount = lineAmount;
        user.level = getLevel(user.freezeAmount);
        user.nodeLevel = getNodeLevel(user.freezeAmount.add(user.freeAmount).add(user.lineAmount));

		roundInvestCount[rid] = roundInvestCount[rid].add(1);
		roundInvestMoney[rid] = roundInvestMoney[rid].add(_msgValue());
		if (!isLine()) {
			sendFeeToDevAddr(_msgValue());
			countBonus_All(user.userAddress);
		} else {
			lineArrayMapping[rid].push(user.id);
		}

        emit InvestEvent(_msgSender(), code, rCode, _msgValue(), now);
	}

    /**
     * @dev Show contract state view
     * @return contract state view
     */
    function stateView()
        public
        view
        returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint)
    {
		return (
            _getCurrentUserID(),
            rid,
            startTime,
            canSetStartTime,
            roundInvestCount[rid],
            roundInvestMoney[rid],
            bonuslimit,
            sendLimit,
            withdrawLimit,
            lineStatus,
            lineArrayMapping[rid].length
		);
	}

    /**
     * @dev determine if contract open
     * @return bool
     */
	function isOpen()
        public
        view
        returns (bool)
    {
		return startTime != 0 && now > startTime;
	}

    /**
     * @dev Whether bonus is calculated when determining contract investment
     * @return bool
     */
	function isLine()
        private
        view
        returns (bool)
    {
		return lineStatus != 0;
	}

    /**
     * @dev get the user id of the round ID or current round [lineArrayMapping] based on the index
     * @param index the index of [lineArrayMapping]
     * @param roundId round ID (Go to the current for empty)
     * @return user ID
     */
	function getLineUserId(uint index, uint roundId)
        public
        view
        returns (uint)
    {
		require(checkWhitelist(), "Permission denied");
		if (roundId == 0) {
			roundId = rid;
		}
		return lineArrayMapping[rid][index];
	}

    /**
     * @dev get the user info based on user ID and round ID
     * @param addr user address
     * @param roundId round ID (Go to the current for empty)
     * @param rewardIndex user current index of award
     * @param useRewardIndex use user current index of award
     * @return user info
     */
	function getUserByAddress(
        address addr,
        uint roundId,
        uint rewardIndex,
        bool useRewardIndex
    )
        public
        view
        returns (uint[17] memory info, string memory code, string memory rCode)
    {
		require(checkWhitelist() || _msgSender() == addr, "Permission denied for view user's privacy");

		if (roundId == 0) {
			roundId = rid;
		}

        uint[2] memory user_data;
        (user_data, code, rCode) = _getUserInfo(addr);
        uint user_id = user_data[0];
        uint user_status = user_data[1];

		User memory user = userRoundMapping[roundId][addr];

        uint historyDayBonusAmount = 0;
        uint settlementbonustime = 0;
        if (useRewardIndex)
        {
            AwardData memory awData = userAwardDataMapping[roundId][user.userAddress][rewardIndex];
            historyDayBonusAmount = awData.staticAmount;
            settlementbonustime = awData.time;
        }

        uint grantAmount = 0;
		if (user.id > 0 && user.freezeAmount >= ethWei.mul(1) && user.freezeAmount <= bonuslimit && user.investTimes < 5 && user_status != 1) {
            if (!useRewardIndex)
            {
                grantAmount = grantAmount.add(user.dayBonusAmount);
            }
		}

        grantAmount = grantAmount.add(getBonusAmount_Dynamic(addr, roundId, rewardIndex, useRewardIndex));

		info[0] = user_id;
		info[1] = user.lineAmount;//bonus calculation mode line
        info[2] = user.freezeAmount;//invest lock
        info[3] = user.freeAmount;//invest out unlock
        info[4] = user.dayBonusAmount;//Daily bonus amount (static bonus)
        info[5] = user.bonusAmount;//add up static bonus amonut (static bonus)
        info[6] = grantAmount;//No settlement of invitation bonus amount (dynamic bonus)
		info[7] = user.inviteAmonut;//add up invite bonus amonut (dynamic bonus)
        info[8] = user.level;//user level
        info[9] = user.nodeLevel;//user node Level
        info[10] = _getRCodeMappingLength(code);//user node number
        info[11] = user.investTimes;//settlement bonus number
		info[12] = user.rewardIndex;//user current index of award
        info[13] = user.lastRwTime;//last settlement time
        info[14] = user_status;//user status
        info[15] = historyDayBonusAmount;//history daily bonus amount (static bonus) (reward Index is not zero)
        info[16] = settlementbonustime;//history daily settlement bonus time (reward Index is not zero)

		return (info, code, rCode);
	}

    /**
     * @dev Calculate the bonus (All)
     * @param addr user address
     */
	function countBonus_All(address addr)
        private
    {
		User storage user = userRoundMapping[rid][addr];
		if (user.id == 0) {
			return;
		}
		uint staticScale = getScaleByLevel(user.level);
		user.dayBonusAmount = user.freezeAmount.mul(staticScale).div(1000);
		user.investTimes = 0;

        uint[2] memory user_data;
        string memory user_rCode;
        (user_data, , user_rCode) = _getUserInfo(addr);
        uint user_status = user_data[1];

		if (user.freezeAmount >= ethWei.mul(1) && user.freezeAmount <= bonuslimit && user_status == 0) {
			countBonus_Dynamic(user_rCode, user.freezeAmount, staticScale);
		}
	}

    /**
     * @dev Calculate the bonus (dynamic)
     * @param rCode user recommend code
     * @param money invest money
     * @param staticScale static scale
     */
	function countBonus_Dynamic(string memory rCode, uint money, uint staticScale)
        private
    {
		string memory tmpReferrerCode = rCode;

		for (uint i = 1; i <= 25; i++) {
			if (tmpReferrerCode.compareStr("")) {
				break;
			}
			address tmpUserAddr = _getCodeMapping(tmpReferrerCode);
			User memory tmpUser = userRoundMapping[rid][tmpUserAddr];

            string memory tmpUser_rCode;
            (, , tmpUser_rCode) = _getUserInfo(tmpUserAddr);

			if (tmpUser.freezeAmount.add(tmpUser.freeAmount).add(tmpUser.lineAmount) == 0) {
				tmpReferrerCode = tmpUser_rCode;
				continue;
			}

            //use max Recommend Level Scale
            //The actual proportion is used for settlement
			uint recommendScale = getRecommendScaleByLevelAndTim(3, i);
			uint moneyResult = 0;
			if (money <= ethWei.mul(15)) {
				moneyResult = money;
			} else {
				moneyResult = ethWei.mul(15);
			}

			if (recommendScale != 0) {
				uint tmpDynamicAmount = moneyResult.mul(staticScale).mul(recommendScale);
				tmpDynamicAmount = tmpDynamicAmount.div(1000).div(100);
				recordAwardData(tmpUserAddr, tmpDynamicAmount, tmpUser.rewardIndex, i);
			}
			tmpReferrerCode = tmpUser_rCode;
		}
	}

    /**
     * @dev Record bonus data
     * @param addr user address
     * @param awardAmount Calculated award amount
     * @param rewardIndex user current index of award
     * @param times The layer number of recommended
     */
	function recordAwardData(address addr, uint awardAmount, uint rewardIndex, uint times)
        private
    {
		for (uint i = 0; i < 5; i++) {
			AwardData storage awData = userAwardDataMapping[rid][addr][rewardIndex.add(i)];
			if (times == 1) {
				awData.oneInvAmount = awData.oneInvAmount.add(awardAmount);
			}
			if (times == 2) {
				awData.twoInvAmount = awData.twoInvAmount.add(awardAmount);
			}
			awData.threeInvAmount = awData.threeInvAmount.add(awardAmount);
		}
	}

    /**
     * @dev send fee to the develop addr
     * @param amount send amount (4%)
     */
	function sendFeeToDevAddr(uint amount)
        private
    {
        sendMoneyToUser(devAddr, amount.div(25));
	}

    /**
     * @dev  get the bonus bmount based on user address and reward Index  (dynamic)
     * @param addr user address
     * @param roundId round ID
     * @param rewardIndex user current index of award
     * @param useRewardIndex use user current index of award
     * @return bonus amount
     */
	function getBonusAmount_Dynamic(
        address addr,
        uint roundId,
        uint rewardIndex,
        bool useRewardIndex
    )
        private
        view
        returns (uint)
    {
        uint resultAmount = 0;
		User memory user = userRoundMapping[roundId][addr];

        if (!useRewardIndex) {
			rewardIndex = user.rewardIndex;
		}

        uint[2] memory user_data;
        (user_data, , ) = _getUserInfo(addr);
        uint user_status = user_data[1];

        uint lineAmount = user.freezeAmount.add(user.freeAmount).add(user.lineAmount);
		if (user_status == 0 && lineAmount >= ethWei.mul(1) && lineAmount <= withdrawLimit) {
			uint inviteAmount = 0;
			AwardData memory awData = userAwardDataMapping[roundId][user.userAddress][rewardIndex];
            uint lineValue = lineAmount.div(ethWei);
            if (lineValue >= 15) {
                inviteAmount = inviteAmount.add(awData.threeInvAmount);
            } else {
                if (user.nodeLevel == 1 && lineAmount >= ethWei.mul(1) && awData.oneInvAmount > 0) {
                    //dev getRecommendScaleByLevelAndTim(3, 1)/getRecommendScaleByLevelAndTim(1, 1)=2   100/50=2
                    inviteAmount = inviteAmount.add(awData.oneInvAmount.div(15).mul(lineValue).div(2));
                }
                if (user.nodeLevel == 2 && lineAmount >= ethWei.mul(1) && (awData.oneInvAmount > 0 || awData.twoInvAmount > 0)) {
                    //mul getRecommendScaleByLevelAndTim(3, 1)  100 →  getRecommendScaleByLevelAndTim(2, 1)  70
                    inviteAmount = inviteAmount.add(awData.oneInvAmount.div(15).mul(lineValue).mul(7).div(10));
                    //mul getRecommendScaleByLevelAndTim(3, 2)  70 →  getRecommendScaleByLevelAndTim(2, 2)  50
                    inviteAmount = inviteAmount.add(awData.twoInvAmount.div(15).mul(lineValue).mul(5).div(7));
                }
                if (user.nodeLevel == 3 && lineAmount >= ethWei.mul(1) && awData.threeInvAmount > 0) {
                    inviteAmount = inviteAmount.add(awData.threeInvAmount.div(15).mul(lineValue));
                }
                if (user.nodeLevel < 3) {
                    //bonus burn
                    uint burnScale = getBurnScaleByLevel(user.nodeLevel);
                    inviteAmount = inviteAmount.mul(burnScale).div(10);
                }
            }
            resultAmount = resultAmount.add(inviteAmount);
		}

        return resultAmount;
	}
}
