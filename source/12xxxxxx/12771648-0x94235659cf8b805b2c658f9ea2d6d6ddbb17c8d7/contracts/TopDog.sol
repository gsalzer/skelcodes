// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./BoneToken.sol";
import "./BoneLocker.sol";


interface IMigratorShib {
    // Perform LP token migration from legacy UniswapV2 to ShibaSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // ShibaSwap must mint EXACTLY the same amount of ShibaSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// TopDog is the master of Bone. He can make Bone and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once BONE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract TopDog is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of BONEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBonePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBonePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BONEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that BONEs distribution occurs.
        uint256 accBonePerShare; // Accumulated BONEs per share, times 1e12. See below.
    }

    // The BONE TOKEN!
    BoneToken public bone;
    // The Bone Token Locker contract
    BoneLocker public boneLocker;
    // Dev address.
    address public devBoneDistributor;

    address public tBoneBoneDistributor;
    address public xShibBoneDistributor;
    address public xLeashBoneDistributor;

    uint256 public devPercent;
    uint256 public tBonePercent;
    uint256 public xShibPercent;
    uint256 public xLeashPercent;

    // Block number when bonus BONE period ends.
    uint256 public bonusEndBlock;
    // BONE tokens created per block.
    uint256 public bonePerBlock;
    // Bonus muliplier for early bone makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorShib public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BONE mining starts.
    uint256 public startBlock;
    // reward percentage to be sent to user directly
    uint256 public rewardMintPercent;
    // devReward percentage to be sent to user directly
    uint256 public devRewardMintPercent;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event RewardPerBlock(address indexed user, uint _newReward);
    event SetAddress(string indexed which, address indexed user, address newAddr);
    event SetPercent(string indexed which, address indexed user, uint256 newPercent);


    constructor(
        BoneToken _bone,
        BoneLocker _boneLocker,
        address _devBoneDistributor,
        address _tBoneBoneDistributor,
        address _xShibBoneDistributor,
        address _xLeashBoneDistributor,
        uint256 _bonePerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _rewardMintPercent,
        uint256 _devRewardMintPercent
    ) public {
        require(address(_bone) != address(0), "_bone is a zero address");
        require(address(_boneLocker) != address(0), "_boneLocker is a zero address");
        bone = _bone;
        boneLocker = _boneLocker;
        devBoneDistributor = _devBoneDistributor;
        bonePerBlock = _bonePerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;

        tBoneBoneDistributor = _tBoneBoneDistributor;
        xShibBoneDistributor = _xShibBoneDistributor;
        xLeashBoneDistributor = _xLeashBoneDistributor;

        rewardMintPercent = _rewardMintPercent;
        devRewardMintPercent = _devRewardMintPercent;

        devPercent = 10;
        tBonePercent = 1;
        xShibPercent = 3;
        xLeashPercent = 1;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated lpToken");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accBonePerShare: 0
        }));
    }

    // update Reward Rate
    function updateRewardPerBlock(uint256 _perBlock) public onlyOwner {
        massUpdatePools();
        bonePerBlock = _perBlock;
        emit RewardPerBlock(msg.sender, _perBlock);
    }

    // Update the given pool's BONE allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorShib _migrator) public onlyOwner {
        migrator = _migrator;
        emit SetAddress("Migrator", msg.sender, address(_migrator));
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_from < startBlock) {
            _from = startBlock;
        }
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // View function to see pending BONEs on frontend.
    function pendingBone(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBonePerShare = pool.accBonePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 boneReward = multiplier.mul(bonePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accBonePerShare = accBonePerShare.add(boneReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accBonePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
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
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 boneReward = multiplier.mul(bonePerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        uint256 devBoneReward = boneReward.mul(devPercent).div(100); // devPercent rewards to dev address
        bone.mint(devBoneDistributor, devBoneReward.mul(devRewardMintPercent).div(100)); // partial devPercent rewards to dev address

        if(devRewardMintPercent != 100) {
            bone.mint(address(boneLocker), devBoneReward.sub(devBoneReward.mul(devRewardMintPercent).div(100))); // rest devPercent rewards locked to bone token contract
            boneLocker.lock(devBoneDistributor, devBoneReward.sub(devBoneReward.mul(devRewardMintPercent).div(100)), true);
        }
        bone.mint(tBoneBoneDistributor, boneReward.mul(tBonePercent).div(100)); // tBonePercent rewards to tBoneBoneDistributor address
        bone.mint(xShibBoneDistributor, boneReward.mul(xShibPercent).div(100)); // xShibPercent rewards to xShibBoneDistributor address
        bone.mint(xLeashBoneDistributor, boneReward.mul(xLeashPercent).div(100)); // xLeashPercent rewards to xLeashBoneDistributor address
        bone.mint(address(this), boneReward);

        pool.accBonePerShare = pool.accBonePerShare.add(boneReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to TopDog for BONE allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accBonePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                // safeBoneTransfer(msg.sender, pending);
                uint256 sendAmount = pending.mul(rewardMintPercent).div(100);
                safeBoneTransfer(msg.sender, sendAmount);
                if(rewardMintPercent != 100) {
                    safeBoneTransfer(address(boneLocker), pending.sub(sendAmount)); // Rest amount sent to Bone token contract
                    boneLocker.lock(msg.sender, pending.sub(sendAmount), false); //function called for token time-lock
                }
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBonePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from TopDog.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accBonePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
                uint256 sendAmount = pending.mul(rewardMintPercent).div(100);
                safeBoneTransfer(msg.sender, sendAmount);
                if(rewardMintPercent != 100) {
                    safeBoneTransfer(address(boneLocker), pending.sub(sendAmount)); // Rest amount sent to Bone token contract
                    boneLocker.lock(msg.sender, pending.sub(sendAmount), false); //function called for token time-lock
                }
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBonePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe bone transfer function, just in case if rounding error causes pool to not have enough BONEs.
    function safeBoneTransfer(address _to, uint256 _amount) internal {
        uint256 boneBal = bone.balanceOf(address(this));
        if (_amount > boneBal) {
            bone.transfer(_to, boneBal);
        } else {
            bone.transfer(_to, _amount);
        }
    }

    // Update boneLocker address by the owner.
    function boneLockerUpdate(address _boneLocker) public onlyOwner {
        boneLocker = BoneLocker(_boneLocker);
    }

    // Update dev bone distributor address by the owner.
    function devBoneDistributorUpdate(address _devBoneDistributor) public onlyOwner {
        devBoneDistributor = _devBoneDistributor;
    }

    // Update rewardMintPercent value, currently set to 33%, called by the owner
    function setRewardMintPercent(uint256 _newPercent) public onlyOwner{
        rewardMintPercent = _newPercent;
        emit SetPercent("RewardMint", msg.sender, _newPercent);
    }

    // Update devRewardMintPercent value, currently set to 50%, called by the owner
    function setDevRewardMintPercent(uint256 _newPercent) public onlyOwner{
        devRewardMintPercent = _newPercent;
        emit SetPercent("DevRewardMint", msg.sender, _newPercent);
    }

    // Update locking period for users and dev
    function setLockingPeriod(uint256 _newLockingPeriod, uint256 _newDevLockingPeriod) public onlyOwner{
        boneLocker.setLockingPeriod(_newLockingPeriod, _newDevLockingPeriod);
    }

    // Call emergency withdraw to transfer bone tokens to any other address, onlyOwner function
    function callEmergencyWithdraw(address _to) public onlyOwner{
        boneLocker.emergencyWithdrawOwner(_to);
    }

    // Update tBoneBoneDistributor address by the owner.
    function tBoneBoneDistributorUpdate(address _tBoneBoneDistributor) public onlyOwner {
        tBoneBoneDistributor = _tBoneBoneDistributor;
        emit SetAddress("tBone-BoneDistributor", msg.sender, _tBoneBoneDistributor);
    }

    // Update xShibBoneDistributor address by the owner.
    function xShibBoneDistributorUpdate(address _xShibBoneDistributor) public onlyOwner {
        xShibBoneDistributor = _xShibBoneDistributor;
        emit SetAddress("xShib-BoneDistributor", msg.sender, _xShibBoneDistributor);
    }

    // Update xLeashBoneDistributor address by the owner.
    function xLeashBoneDistributorUpdate(address _xLeashBoneDistributor) public onlyOwner {
        xLeashBoneDistributor = _xLeashBoneDistributor;
        emit SetAddress("xLeash-BoneDistributor", msg.sender, _xLeashBoneDistributor);
    }

    // Update devPercent by the owner.
    function devPercentUpdate(uint _devPercent) public onlyOwner {
        require(_devPercent <= 10, "topDog: Percent too high");
        devPercent = _devPercent;
        emit SetPercent("Dev share", msg.sender, _devPercent);
    }

    // Update tBonePercent by the owner.
    function tBonePercentUpdate(uint _tBonePercent) public onlyOwner {
        tBonePercent = _tBonePercent;
        emit SetPercent("tBone share", msg.sender, _tBonePercent);
    }

    // Update xShibPercent by the owner.
    function xShibPercentUpdate(uint _xShibPercent) public onlyOwner {
        xShibPercent = _xShibPercent;
        emit SetPercent("xShib share", msg.sender, _xShibPercent);
    }

    // Update xLeashPercent by the owner.
    function xLeashPercentUpdate(uint _xLeashPercent) public onlyOwner {
        xLeashPercent = _xLeashPercent;
        emit SetPercent("xLeash share", msg.sender, _xLeashPercent);
    }
}


