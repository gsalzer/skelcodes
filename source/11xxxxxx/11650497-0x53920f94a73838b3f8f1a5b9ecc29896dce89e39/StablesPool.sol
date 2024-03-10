// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import './IInvitation.sol';
// Note that this pool has no minter key of ibac (rewards).
// Instead, the governance will call ibac.distributeReward and send reward to this pool at the beginning.
contract StablesPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address internal team = 0x3a0910E373aa1845E439f7009326A17F4b612965; 
    address internal government = 0x4C0b98cF1761425A6a23a16cC1bD5c51C1638703; 
    address internal insurance  = 0xaa5de6aD842b4eB26b85511e3f4A85DAFBd5fD68; 
    address public governance;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ibacs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accibacPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accibacPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        uint256 accumulatedStakingPower; // will accumulate every time user harvest
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 lastRewardBlock; // Last block number that ibacs distribution occurs.
        uint256 accibacPerShare; // Accumulated ibacs per share, times 1e18. See below.
    }

    // The ibac TOKEN!
    IERC20 public ibac;

    IInvitation public invitation;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public startBlock;

    uint256 public poolLength = 5; // DAI, USDC, USDT, BUSD, yCRV

    uint256 public constant BLOCKS_PER_WEEK = 46500;

    uint256[] public epochTotalRewards = [40000 ether, 40000 ether, 60000 ether, 60000 ether];

    // Block number when each epoch ends.
    uint[4] public epochEndBlocks;

    // Reward per block for each of 4 epochs (last item is equal to 0 - for sanity).
    uint[5] public epochibacPerBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event InvitationReward(address indexed user, uint8 indexed lv, uint256 amount);

    constructor(
        address _ibac,
        uint256 _startBlock,
        address[] memory _lpTokens,
        address _invitation
    ) public {
        // require(block.number < _startBlock, "late");
        if (_ibac != address(0)) ibac = IERC20(_ibac);
        if (_invitation != address(0)) invitation = IInvitation(_invitation);
        startBlock = _startBlock; // supposed to be 11,465,000 (Wed Dec 16 2020 15:00:00 UTC)
        epochEndBlocks[0] = startBlock + BLOCKS_PER_WEEK;
        uint256 i;
        for (i = 1; i <= 3; ++i) {
            epochEndBlocks[i] = epochEndBlocks[i - 1] + BLOCKS_PER_WEEK;
        }
        for (i = 0; i <= 3; ++i) {
            epochibacPerBlock[i] = epochTotalRewards[i].div(BLOCKS_PER_WEEK);
        }
        epochibacPerBlock[4] = 0;
        if (_lpTokens.length == 0) {
            _addPool(address(0x6B175474E89094C44Da98b954EedeAC495271d0F)); // DAI
            _addPool(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)); // USDC
            _addPool(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // USDT
            _addPool(address(0x57Ab1E02fEE23774580C119740129eAC7081e9D3)); // SUSD
            _addPool(address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8)); // yCRV
        } else {
            require(_lpTokens.length == poolLength, "Need exactly 5 lpToken address");
            for (i = 0; i < poolLength; ++i) {
                _addPool(_lpTokens[i]);
            }
        }
    }

    // Add a new lp to the pool. Called in the constructor only.
    function _addPool(address _lpToken) internal {
        require(_lpToken != address(0), "!_lpToken");
        poolInfo.push(
            PoolInfo({
            lpToken : IERC20(_lpToken),
            lastRewardBlock : startBlock,
            accibacPerShare : 0
            })
        );
    }

    // Return reward multiplier over the given _from to _to block.
    function getGeneratedReward(uint256 _from, uint256 _to) public view returns (uint256) {
        for (uint8 epochId = 4; epochId >= 1; --epochId) {
            if (_to >= epochEndBlocks[epochId - 1]) {
                if (_from >= epochEndBlocks[epochId - 1]) return _to.sub(_from).mul(epochibacPerBlock[epochId]);
                uint256 _generatedReward = _to.sub(epochEndBlocks[epochId - 1]).mul(epochibacPerBlock[epochId]);
                if (epochId == 1) return _generatedReward.add(epochEndBlocks[0].sub(_from).mul(epochibacPerBlock[0]));
                for (epochId = epochId - 1; epochId >= 1; --epochId) {
                    if (_from >= epochEndBlocks[epochId - 1]) return _generatedReward.add(epochEndBlocks[epochId].sub(_from).mul(epochibacPerBlock[epochId]));
                    _generatedReward = _generatedReward.add(epochEndBlocks[epochId].sub(epochEndBlocks[epochId - 1]).mul(epochibacPerBlock[epochId]));
                }
                return _generatedReward.add(epochEndBlocks[0].sub(_from).mul(epochibacPerBlock[0]));
            }
        }
        return _to.sub(_from).mul(epochibacPerBlock[0]);
    }

    // View function to see pending ibacs on frontend.
    function pendingiBasisDollar(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accibacPerShare = pool.accibacPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardBlock, block.number);
            accibacPerShare = accibacPerShare.add(_generatedReward.div(poolLength).mul(1e18).div(lpSupply));
        }
        return user.amount.mul(accibacPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 _generatedReward = getGeneratedReward(pool.lastRewardBlock, block.number);
        pool.accibacPerShare = pool.accibacPerShare.add(_generatedReward.div(poolLength).mul(1e18).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit by Invitee.
    function depositByInvitee(uint256 _pid, uint256 _amount,address inviter) public {
        address inviter2 = invitation.getInviter(inviter);
        if(inviter2 !=address(0)){
            invitation.setInviter(msg.sender,inviter);
         }else{  // If your inviter did not deposit.
            invitation.setInviter(msg.sender,address(1));
         }
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accibacPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeibacTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accibacPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Deposit .
    function deposit(uint256 _pid, uint256 _amount) public {
        address inviter = invitation.getInviter(msg.sender);
        if(inviter == address(0)) invitation.setInviter(msg.sender,address(1));
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accibacPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeibacTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accibacPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accibacPerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeibacTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(_sender, _amount.mul(97).div(100));
            pool.lpToken.safeTransfer(team, _amount.mul(3).div(100));
        }
        user.rewardDebt = user.amount.mul(pool.accibacPerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount.mul(97).div(100));
        pool.lpToken.safeTransfer(team, user.amount.mul(3).div(100));
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe ibac transfer function, just in case if rounding error causes pool to not have enough ibacs.
    function safeibacTransfer(address _to, uint256 _amount) internal {
        uint256 _ibacBal = ibac.balanceOf(address(this));
        address inviter = invitation.getInviter(_to);
        address inviter2 = invitation.getInviter(inviter);
        if (_ibacBal > 0) {
            uint256 amount = _amount > _ibacBal ? _ibacBal : _amount;
            ibac.transfer(_to, amount); //%100
            tryibacTransfer(team,amount.mul(5).div(100), 0);
            tryibacTransfer(government,amount.mul(3).div(100), 0);
            tryibacTransfer(insurance,amount.mul(2).div(100), 0);
            if(inviter!=address(0) && inviter != address(1)) tryibacTransfer(inviter,amount.mul(2).div(100), 1);
            if(inviter2!=address(0) && inviter2 != address(1)) tryibacTransfer(inviter2,amount.mul(1).div(100), 2);
        }
    } 

    function tryibacTransfer(address _to, uint256 _amount,uint8 lv) internal {
            try 
              ibac.transfer(_to, _amount)
             {
                 if(lv != 0) emit InvitationReward(_to, lv, _amount);   
             }
            catch {}
    } 

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        require(_governance != address(0), "zero");
        governance = _governance;
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        if (block.number < epochEndBlocks[3] + BLOCKS_PER_WEEK * 12) {
            // do not allow to drain lpToken if less than 3 months after farming
            require(_token != ibac, "!ibac");
            for (uint256 pid = 0; pid < poolLength; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.lpToken, "!pool.lpToken");
            }
        }
        _token.safeTransfer(to, amount);
    }
}

