//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.16;


import "./SafeMath.sol";
import "./math.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
 
import "./interfaceFarming.sol";

import "./IntMonaToken.sol";

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



contract MONA__Farming is IFarming, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    bool public tokensAlreadyBurn = false;
    uint256 public stakeBudget = 0;
    uint256 public stakeBudgetForBurn = 0;
    uint256 public rewardRate = 0;
    
    uint256 public halvingTime = 0;
    uint256 public lastUpdateTime = 0;
    
    uint256 public rewardsDuration = 56 days;
    uint256 public rewardPerTokenStored;


    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;


    address public monaToken; 
    
    MonaToken private monatoken;

    constructor(
        address _monaToken,
        address _rewardsToken,
        address _stakingToken,
        uint256 _stakeBudget
    ) public {
        
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        stakeBudget = _stakeBudget.mul(50).div(100);
        stakeBudgetForBurn = _stakeBudget;
        
        monatoken = MonaToken( _monaToken );
        
        rewardRate = stakeBudget.div( rewardsDuration );
        rewardPerTokenStored = rewardPerToken();

        lastUpdateTime = block.timestamp;
        halvingTime = block.timestamp.add( rewardsDuration );

    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, halvingTime);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored
                .add(
                    lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
                );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account]
                    .mul( rewardPerToken().sub(userRewardPerTokenPaid[account]) )
                    .div(1e18)
                    .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount <= _balances[msg.sender] && _balances[msg.sender] > 0, "Bad withdraw amount.");

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        unstake(_balances[msg.sender]);
        getReward();
    }

    function tooManyTokensSoBurnThem() external onlyOwner{
        require( tokensAlreadyBurn == false, "Token already burned");
        
        uint256 tokenToBurn = monatoken.balanceOf( address(this) ).sub( stakeBudgetForBurn );
        
        monatoken.burn( tokenToBurn );
        
        tokensAlreadyBurn = true;
    }

    modifier updateReward(address account) {

        if (block.timestamp >= halvingTime) {
            stakeBudget = stakeBudget.mul(50).div(100);
            rewardRate = stakeBudget.div( rewardsDuration );
            halvingTime = halvingTime.add( rewardsDuration );
        }


        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
