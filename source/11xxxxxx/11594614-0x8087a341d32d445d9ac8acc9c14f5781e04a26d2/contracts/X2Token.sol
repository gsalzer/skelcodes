// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/token/IERC20.sol";
import "./libraries/token/SafeERC20.sol";
import "./libraries/math/SafeMath.sol";
import "./libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IX2Fund.sol";
import "./interfaces/IX2Market.sol";
import "./interfaces/IX2Token.sol";

// rewards code adapated from https://github.com/trusttoken/smart-contracts/blob/master/contracts/truefi/TrueFarm.sol
contract X2Token is IERC20, IX2Token, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Ledger {
        uint128 balance;
        uint128 cost;
    }

    // max uint128 has 38 digits
    // the initial divisor has 10 digits
    // each 1 wei of rewards will increase cumulativeRewardPerToken by
    // 1*10^10 (PRECISION 10^20 / divisor 10^10)
    // assuming a supply of only 1 wei of X2Tokens
    // so total rewards of up to 10^28 wei or 1 billion ETH is supported
    struct Reward {
        uint128 claimable;
        uint128 previousCumulativeRewardPerToken;
    }

    uint256 constant PRECISION = 1e20;
    uint256 constant MAX_BALANCE = uint128(-1);
    uint256 constant MAX_REWARD = uint128(-1);

    string public name = "X2";
    string public symbol = "X2";
    uint8 public constant decimals = 18;

    // _totalSupply also tracks totalStaked
    uint256 public override _totalSupply;

    address public override market;
    address public factory;
    address public override distributor;

    // ledgers track balances and costs
    mapping (address => Ledger) public ledgers;
    mapping (address => mapping (address => uint256)) public allowances;

    // track previous cumulated rewards and claimable rewards for accounts
    mapping(address => Reward) public rewards;
    // track overall cumulative rewards
    uint256 public cumulativeRewardPerToken;
    // track total rewards
    uint256 public totalRewards;

    bool public isInitialized;

    event Claim(address receiver, uint256 amount);

    modifier onlyFactory() {
        require(msg.sender == factory, "X2Token: forbidden");
        _;
    }

    modifier onlyMarket() {
        require(msg.sender == market, "X2Token: forbidden");
        _;
    }

    receive() external payable {}

    function initialize(address _factory, address _market) public {
        require(!isInitialized, "X2Token: already initialized");
        isInitialized = true;
        factory = _factory;
        market = _market;
    }

    function setDistributor(address _distributor) external override onlyFactory {
        distributor = _distributor;
    }

    function setInfo(string memory _name, string memory _symbol) external override onlyFactory {
        name = _name;
        symbol = _symbol;
    }

    function mint(address _account, uint256 _amount, uint256 _divisor) external override onlyMarket {
        _mint(_account, _amount, _divisor);
    }

    function burn(address _account, uint256 _amount, bool _distribute) external override onlyMarket {
        _burn(_account, _amount, _distribute);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply.div(getDivisor());
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "X2Token: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function claim(address _receiver) external nonReentrant {
        address _account = msg.sender;
        uint256 cachedTotalSupply = _totalSupply;
        _updateRewards(_account, cachedTotalSupply, true);

        Reward storage reward = rewards[_account];
        uint256 rewardToClaim = reward.claimable;
        reward.claimable = 0;

        (bool success,) = _receiver.call{value: rewardToClaim}("");
        require(success, "X2Token: transfer failed");

        emit Claim(_receiver, rewardToClaim);
    }

    function getDivisor() public override view returns (uint256) {
        return IX2Market(market).getDivisor(address(this));
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return uint256(ledgers[_account].balance).div(getDivisor());
    }

    function _balanceOf(address _account) public view override returns (uint256) {
        return uint256(ledgers[_account].balance);
    }

    function costOf(address _account) public override view returns (uint256) {
        return uint256(ledgers[_account].cost);
    }

    function getReward(address _account) public override view returns (uint256) {
        return uint256(rewards[_account].claimable);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "X2Token: transfer from the zero address");
        require(_recipient != address(0), "X2Token: transfer to the zero address");

        uint256 divisor = getDivisor();
        _decreaseBalance(_sender, _amount, divisor, true);
        _increaseBalance(_recipient, _amount, divisor);

        emit Transfer(_sender, _recipient, _amount);
    }

    function _mint(address _account, uint256 _amount, uint256 _divisor) private {
        require(_account != address(0), "X2Token: mint to the zero address");

        _increaseBalance(_account, _amount, _divisor);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount, bool _distribute) private {
        require(_account != address(0), "X2Token: burn from the zero address");

        uint256 divisor = getDivisor();
        _decreaseBalance(_account, _amount, divisor, _distribute);

        emit Transfer(_account, address(0), _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "X2Token: approve from the zero address");
        require(_spender != address(0), "X2Token: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _increaseBalance(address _account, uint256 _amount, uint256 _divisor) private {
        if (_amount == 0) { return; }

        uint256 cachedTotalSupply = _totalSupply;
        _updateRewards(_account, cachedTotalSupply, true);

        uint256 scaledAmount = _amount.mul(_divisor);
        Ledger memory ledger = ledgers[_account];

        uint256 nextBalance = uint256(ledger.balance).add(scaledAmount);
        require(nextBalance < MAX_BALANCE, "X2Token: balance limit exceeded");

        uint256 cost = uint256(ledger.cost).add(_amount);
        require(cost < MAX_BALANCE, "X2Token: cost limit exceeded");

        ledgers[_account] = Ledger(
            uint128(nextBalance),
            uint128(cost)
        );

        _totalSupply = cachedTotalSupply.add(scaledAmount);
    }

    function _decreaseBalance(address _account, uint256 _amount, uint256 _divisor, bool _distribute) private {
        if (_amount == 0) { return; }

        uint256 cachedTotalSupply = _totalSupply;
        _updateRewards(_account, cachedTotalSupply, _distribute);

        uint256 scaledAmount = _amount.mul(_divisor);
        Ledger memory ledger = ledgers[_account];

        // since _amount is not zero, so scaledAmount should not be zero
        // if ledger.balance is zero, then uint256(ledger.balance).sub(scaledAmount)
        // should fail, so we can calculate cost with ...div(ledger.balance)
        // as ledger.balance should not be zero
        uint256 nextBalance = uint256(ledger.balance).sub(scaledAmount);
        uint256 cost = uint256(ledger.cost).mul(nextBalance).div(ledger.balance);

        ledgers[_account] = Ledger(
            uint128(nextBalance),
            uint128(cost)
        );

        _totalSupply = cachedTotalSupply.sub(scaledAmount);
    }

    function _updateRewards(address _account, uint256 _cachedTotalSupply, bool _distribute) private {
        uint256 blockReward;

        if (_distribute && distributor != address(0)) {
            blockReward = IX2Fund(distributor).distribute();
        }

        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        // only update cumulativeRewardPerToken when there are stakers, i.e. when _totalSupply > 0
        // if blockReward == 0, then there will be no change to cumulativeRewardPerToken
        if (_totalSupply > 0 && blockReward > 0) {
            // PRECISION is 10^20 and the BASE_DIVISOR is 10^10
            // cachedTotalSupply = _totalSupply * divisor
            // the divisor will be around 10^10
            // if 1000 ETH worth is minted, then cachedTotalSupply = 1000 * 10^18 * 10^10 = 10^31
            // cumulativeRewardPerToken will increase by blockReward * 10^20 / (10^31)
            // if the blockReward is 0.001 ETH, 10^-3 ETH or 10^-3 * 10^18 WEI
            // then cumulativeRewardPerToken will increase by 10^-3 * 10^18 * 10^20 / (10^31)
            // which is 10^35 / 10^31 or 10^4
            // if rewards are distributed every hour then at least 0.168 ETH should be distributed per week
            // so that there will not be precision issues for distribution
            _cumulativeRewardPerToken = _cumulativeRewardPerToken.add(blockReward.mul(PRECISION).div(_cachedTotalSupply));
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // cumulativeRewardPerToken can only increase
        // so if cumulativeRewardPerToken is zero, it means there are no rewards yet
        // return if _cumulativeRewardPerToken > MAX_REWARD to avoid overflows
        if (_cumulativeRewardPerToken == 0 || _cumulativeRewardPerToken > MAX_REWARD) {
            return;
        }

        // ledgers[_account].balance = balance * divisor
        // this divisor will be around 10^10
        // assuming that cumulativeRewardPerToken increases by at least 10^4
        // the claimableReward will increase by balance * 10^10 * 10^4 / 10^20
        // if the total supply is 1000 ETH
        // a user must own at least 10^-6 ETH or 0.000001 ETH worth of tokens to get some rewards
        Reward memory reward = rewards[_account];
        uint256 claimableReward = uint256(reward.claimable).add(
            uint256(ledgers[_account].balance).mul(_cumulativeRewardPerToken.sub(reward.previousCumulativeRewardPerToken)).div(PRECISION)
        );

        if (claimableReward > MAX_REWARD) {
            return;
        }

        rewards[_account] = Reward(
            uint128(claimableReward),
            // update previous cumulative reward for sender
            uint128(_cumulativeRewardPerToken)
        );
    }
}

