pragma solidity ^0.5.2;

import "./DSTokenBase.sol";
import "./Ownable.sol";

interface ILottery {
    function getAvailablePrize() external view returns (uint256);
}

contract Lottoshi is DSTokenBase(0), Ownable {
    uint256 constant internal magnitude = 2 ** 64;
    uint256 constant internal HOUSE_PERCENTAGE = 75; // 7.5%
    uint256 constant internal REFERRAL_PERCENTAGE = 50; // 5%
    uint256 constant internal FOMO_PERCENTAGE = 120; // 12%
    uint256 constant internal PRIZE_LIMIT_TO_INVEST = 50000 ether;
    uint256 constant internal MAX_SUPPLY = 500000 * (10 ** 6);
    string constant public name = "Lottoshi";
    string constant public symbol = "LTS";
    uint256 constant public decimals = 6;

    uint256 public profitPerShare;
    uint256 public totalStakes;
    address payable public lottery;
    bool public decentralized;

    mapping (address => uint256) public stakesOf;
    mapping (address => uint256) public payout;
    mapping (address => uint256) public dividends;

    event Invest(address indexed user, uint256 ethAmount, uint256 tokenAmount, address referee);
    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor (address payable _lottery) public {
        lottery = _lottery;
    }

    function () external {
    }

    function decentralize() external {
        require(lottery == msg.sender, "invalid sender");
        decentralized = true;
    }

    function contribute(address referral) external payable {
        uint256 referralAmount;
        if (referral != address(0)) {
            referralAmount = msg.value * REFERRAL_PERCENTAGE / 300;
            dividends[referral] += referralAmount;
        }
        uint256 houseAmount;
        if (!decentralized) {
            houseAmount = msg.value * HOUSE_PERCENTAGE / 300;
            dividends[owner()] += houseAmount;
        }
        profitPerShare += (msg.value - houseAmount - referralAmount) * magnitude / totalStakes;
    }

    function invest(address referral) public payable {
        uint256 prize = getPrize();
        require(prize < PRIZE_LIMIT_TO_INVEST, "prize is enough");
        uint256 fomoAmount;
        if (totalStakes > 0) {
            fomoAmount = msg.value * FOMO_PERCENTAGE / 1000;
            profitPerShare += fomoAmount * magnitude / totalStakes;
        }
        lottery.transfer(msg.value - fomoAmount);
        uint256 token1 = ethToTokens(prize);
        uint256 token2 = ethToTokens(prize + msg.value);
        uint256 tokenAmount = (token2 - token1) / 1000000000000;
        uint256 referralAmount;
        if (referral != address(0) && referral != msg.sender) {
            referralAmount = tokenAmount / 20;
            stakesOf[referral] += referralAmount;
            payout[referral] += referralAmount * profitPerShare;
            emit Invest(referral, 0, referralAmount, msg.sender);
            emit Transfer(address(0), referral, referralAmount);
            emit Transfer(referral, address(this), referralAmount);
            emit Stake(referral, referralAmount);
        }
        uint256 totalAmount = referralAmount + tokenAmount;
        require(_supply + totalAmount <= MAX_SUPPLY, "exceed max supply");
        stakesOf[msg.sender] += tokenAmount;
        payout[msg.sender] += tokenAmount * profitPerShare;
        _supply += totalAmount;
        totalStakes += totalAmount;
        _balances[address(this)] = totalAmount;
        emit Invest(msg.sender, msg.value, tokenAmount, address(0));
        emit Transfer(address(0), msg.sender, tokenAmount);
        emit Transfer(msg.sender, address(this), tokenAmount);
        emit Stake(msg.sender, tokenAmount);
    }

    function stake(uint256 amount) external {
        internalTransfer(msg.sender, address(this), amount);
        stakesOf[msg.sender] += amount;
        payout[msg.sender] += amount * profitPerShare;
        totalStakes += amount;
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(stakesOf[msg.sender] >= amount, "stakesOf not enough");
        withdrawDividends(msg.sender);
        payout[msg.sender] -= amount * profitPerShare;
        stakesOf[msg.sender] -= amount;
        totalStakes -= amount;
        emit Unstake(msg.sender, amount);
        internalTransfer(address(this), msg.sender, amount);
    }

    function withdrawDividends() public {
        withdrawDividends(msg.sender);
    }

    function withdrawDividends(address payable user) internal {
        uint256 dividend = dividendOf(user);
        if (dividend > 0) {
            uint256 dividend2 = dividends[user];
            payout[user] += (dividend - dividend2) * magnitude;
            if (dividend2 > 0) {
                dividends[user] = 0;
            }
            user.transfer(dividend);
            emit Withdraw(user, dividend);
        }
    }

    function dividendOf(address user) public view returns (uint256) {
        return (profitPerShare * stakesOf[user] - payout[user]) / magnitude + dividends[user];
    }

    function ethToTokens(uint256 eth) internal pure returns (uint256) {
        return (sqrt(10000800016000000000000000000000000000000000000 + 4000000000000000000000000 * eth) - 100004000000000000000000) >> 1;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) >> 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) >> 1;
        }
    }

    function getPrize() internal view returns (uint256) {
        return ILottery(lottery).getAvailablePrize();
    }

    function internalTransfer(address src, address dst, uint wad) internal {
        require(_balances[src] >= wad, "ds-token-insufficient-balance");
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);
    }
}

