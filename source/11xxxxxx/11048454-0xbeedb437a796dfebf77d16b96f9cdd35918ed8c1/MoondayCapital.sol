pragma solidity ^0.5.10;

import "./SafeMath.sol";
import "./ERC20Interface.sol";

contract MoondayCapital {
    using SafeMath for uint256;

    uint256 constant public BASE_PERCENT = 10;
    uint256 constant public REFERRAL_PERCENTS = 50;
    uint256 constant public MANAGER_FEE = 30;
    uint256 constant public PARTNER_FEE = 10;
	uint256 constant public DEV_FEE = 10;
	uint256 constant public LOCK_FEE = 50;
    uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public PERCENTS_DAILY = 70;
    uint256 constant public TIME_STEP = 1 days;
	
	ERC20Interface MoondayToken;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    address payable public managerAddress;
    address payable public devAddress;
	address payable public partnerAddress;
	address payable public lockAddress;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
    }

    mapping (address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address payable _managerAddress, address payable _partnerAddress, address payable _devAddress, address payable _lockAddress, address _MoondayToken) public {
        managerAddress = _managerAddress;
        partnerAddress = _partnerAddress;
		devAddress = _devAddress;
		lockAddress = _lockAddress;
        MoondayToken = ERC20Interface(_MoondayToken);
    }

    function invest(address referrer, uint256 amount) public {

        uint256 received = amount.mul(99).div(100);

		MoondayToken.transferFrom(msg.sender, address(this), received);
		MoondayToken.transfer(managerAddress, received.mul(MANAGER_FEE).div(PERCENTS_DIVIDER));
		MoondayToken.transfer(partnerAddress, received.mul(PARTNER_FEE).div(PERCENTS_DIVIDER));
		MoondayToken.transfer(devAddress, received.mul(DEV_FEE).div(PERCENTS_DIVIDER));
		MoondayToken.transfer(lockAddress, received.mul(LOCK_FEE).div(PERCENTS_DIVIDER));

        emit FeePayed(msg.sender, received.mul(MANAGER_FEE.add(PARTNER_FEE).add(DEV_FEE).add(LOCK_FEE)).div(PERCENTS_DIVIDER));

        User storage user = users[msg.sender];

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {

            address upline = user.referrer;
            
			if (upline != address(0)) {
				uint256 _amount = received.mul(REFERRAL_PERCENTS).div(PERCENTS_DIVIDER);
				users[upline].bonus = users[upline].bonus.add(_amount);
				emit RefBonus(upline, msg.sender, _amount);
			}
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(received, 0, block.timestamp));

        totalInvested = totalInvested.add(received);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, received);

    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 userPercentRate = getUserPercentRate(msg.sender);

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(185).div(100)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(185).div(100)) {
                    dividends = (user.deposits[i].amount.mul(185).div(100)).sub(user.deposits[i].withdrawn);
                }

                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            user.bonus = 0;
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = MoondayToken.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;
		
		MoondayToken.transfer(msg.sender, totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);

    }


    function getUserPercentRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        return PERCENTS_DAILY;
    }


    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(185).div(100)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(185).div(100)) {
                    dividends = (user.deposits[i].amount.mul(185).div(100)).sub(user.deposits[i].withdrawn);
                }

                totalDividends = totalDividends.add(dividends);

            }

        }

        return totalDividends;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].bonus;
    }

    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(185).div(100)) {
                return true;
            }
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }
}
