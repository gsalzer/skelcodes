pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LevelsCore.sol";
import "hardhat/console.sol";

// Function that allows people voluntarly migrate into a new pool contract
interface IMigrateToken {
  function deposit() external returns (bool);
}

// Levels Vault distributes fees equally amongst staked pools
// Have fun reading it. Hopefully it's bug-free. God bless.
contract LevelsVault is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many  tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of LEVELS
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accLevelsPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws  tokens to a pool. Here's what happens:
    //   1. The pool's `accLevelsPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 token; // Address of  token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. LEVELS to distribute per block.
    uint256 accLevelsPerShare; // Accumulated LEVELS per share, times 1e12. See below.
    bool withdrawable; // Is this pool withdrawable?
    mapping(address => mapping(address => uint256)) allowance;
  }

  // The LEVELS TOKEN!
  LevelsCore public levels;
  // Dev address.
  address public devaddr;

  // Info of each pool.
  PoolInfo[] public poolInfo;
  // Info of each user that stakes  tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint = 0;

  //// pending rewards awaiting anyone to massUpdate
  uint256 public pendingRewards;

  uint256 public contractStartBlock;
  uint256 public epochCalculationStartBlock;
  uint256 public cumulativeRewardsSinceStart;
  uint256 public rewardsInThisEpoch;
  uint public epoch;

  // Returns fees generated since start of this contract
  function averageFeesPerBlockSinceStart() external view returns (uint averagePerBlock) {
    averagePerBlock = cumulativeRewardsSinceStart.add(rewardsInThisEpoch).div(block.number.sub(contractStartBlock));
  }

  // Returns averge fees in this epoch
  function averageFeesPerBlockEpoch() external view returns (uint256 averagePerBlock) {
    averagePerBlock = rewardsInThisEpoch.div(block.number.sub(epochCalculationStartBlock));
  }

  //Starts a new calculation epoch
  // Because averge since start will not be accurate
  function startNewEpoch() public {
    require(epochCalculationStartBlock + 50000 < block.number, "New epoch not ready yet"); // About a week
    cumulativeRewardsSinceStart = cumulativeRewardsSinceStart.add(rewardsInThisEpoch);
    rewardsInThisEpoch = 0;
    epochCalculationStartBlock = block.number;
    ++epoch;
  }

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );
  event Approval(address indexed owner, address indexed spender, uint256 _pid, uint256 value);

  constructor(
    LevelsCore _levels,
    address _devaddr, 
    address superAdmin
  ) public {
    levels = _levels;
    devaddr = _devaddr;
    contractStartBlock = block.number;
    _superAdmin = superAdmin;
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  // Add a new token pool. Can only be called by the owner. 
  // Note contract owner is meant to be a governance contract allowing LEVELS governance consensus
  function add(
    uint256 _allocPoint,
    IERC20 _token,
    bool _withUpdate,
    bool _withdrawable
  ) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }

    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      require(poolInfo[pid].token != _token,"Error pool already added");
    }

    totalAllocPoint = totalAllocPoint.add(_allocPoint);

    poolInfo.push(
      PoolInfo({
        token: _token,
        allocPoint: _allocPoint,
        accLevelsPerShare: 0,
        withdrawable : _withdrawable
      })
    );
  }

  // Update the given pool's Levels allocation point. Can only be called by the owner.
  // Note contract owner is meant to be a governance contract allowing LEVELS governance consensus

  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }

    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
      _allocPoint
    );
    poolInfo[_pid].allocPoint = _allocPoint;
  }

  // Update the given pool's ability to withdraw tokens
  // Note contract owner is meant to be a governance contract allowing LEVELS governance consensus
  function setPoolWithdrawable(
    uint256 _pid,
    bool _withdrawable
  ) public onlyOwner {
    poolInfo[_pid].withdrawable = _withdrawable;
  }



  // Sets the dev fee for this contract
  // defaults at 10.00%
  // Note contract owner is meant to be a governance contract allowing LEVELS governance consensus
  uint16 DEV_FEE = 1000;
  function setDevFee(uint16 _DEV_FEE) public onlyOwner {
    require(_DEV_FEE <= 1500, 'Dev fee clamped at 15%');
    DEV_FEE = _DEV_FEE;
  }
  uint256 pending_DEV_rewards;

  function getPendingDevFeeRewards() public view returns (uint256) {
      return pending_DEV_rewards;
  }

  // View function to see pending Levels on frontend.
  function pendingLevels(uint256 _pid, address _user)
    public
    view
    returns (uint256)
  {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accLevelsPerShare = pool.accLevelsPerShare;

    return user.amount.mul(accLevelsPerShare).div(1e12).sub(user.rewardDebt);
  }

  // Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    uint allRewards;

    for (uint256 pid = 0; pid < length; ++pid) {
      allRewards = allRewards.add(updatePool(pid));
    }

    pendingRewards = pendingRewards.sub(allRewards);
  }

  uint256 private levelsBalance;
  function addPendingRewards(uint256 _amount) public {
    uint256 newRewards = levels.balanceOf(address(this)).sub(levelsBalance);

    if(newRewards > 0) {
      levelsBalance = levels.balanceOf(address(this)); // If there is no change the balance didn't change
      pendingRewards = pendingRewards.add(newRewards);
      rewardsInThisEpoch = rewardsInThisEpoch.add(newRewards);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) internal returns (uint256 levelsRewardWhole) {
    PoolInfo storage pool = poolInfo[_pid];

    uint256 tokenSupply = pool.token.balanceOf(address(this));
    if (tokenSupply == 0) { // avoids division by 0 errors
      return 0;
    }

    levelsRewardWhole = pendingRewards
      .mul(pool.allocPoint)
      .div(totalAllocPoint);

    uint256 levelsRewardFee = levelsRewardWhole.mul(DEV_FEE).div(10000);
    uint256 levelsRewardToDistribute = levelsRewardWhole.sub(levelsRewardFee);

    pending_DEV_rewards = pending_DEV_rewards.add(levelsRewardFee);

    pool.accLevelsPerShare = pool.accLevelsPerShare.add(
      levelsRewardToDistribute.mul(1e12).div(tokenSupply)
    );

  }

  function claimRewards(uint256 _pid) public{
    updateAndPayOutPending(_pid, msg.sender);
  }

  // Deposit  tokens to LevelsVault for Levels allocation.
  function deposit(uint256 _pid, uint256 _amount) public {
    require(_amount > 0, "Can't accept 0 amount");

    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    massUpdatePools();
    // Transfer pending tokens
    // to user
    updateAndPayOutPending(_pid, msg.sender);


    pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.amount.mul(pool.accLevelsPerShare).div(1e12);
    emit Deposit(msg.sender, _pid, _amount);
  }

  // Test coverage
  // [x] Does user get the deposited amounts?
  // [x] Does user that its deposited for update correcty?
  // [x] Does the depositor get their tokens decreased
  function depositFor(address depositFor, uint256 _pid, uint256 _amount) public {
    // requires no allowances
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][depositFor];

    massUpdatePools();

    // Transfer pending tokens
    // to user
    updateAndPayOutPending(_pid, depositFor); // Update the balances of person that amount is being deposited for

    if(_amount > 0) {
      pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
      user.amount = user.amount.add(_amount); // This is depositedFor address
    }

    user.rewardDebt = user.amount.mul(pool.accLevelsPerShare).div(1e12); /// This is deposited for address
    emit Deposit(depositFor, _pid, _amount);

  }

  // Test coverage
  // [x] Does allowance update correctly?
  function setAllowanceForPoolToken(address spender, uint256 _pid, uint256 value) public {
    PoolInfo storage pool = poolInfo[_pid];
    pool.allowance[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, _pid, value);
  }

  // Test coverage
  // [x] Does allowance decrease?
  // [x] Do oyu need allowance
  // [x] Withdraws to correct address
  function withdrawFrom(address owner, uint256 _pid, uint256 _amount) public{
    PoolInfo storage pool = poolInfo[_pid];
    require(pool.allowance[owner][msg.sender] >= _amount, "withdraw: insufficient allowance");
    pool.allowance[owner][msg.sender] = pool.allowance[owner][msg.sender].sub(_amount);
    _withdraw(_pid, _amount, owner, msg.sender);

  }

  // Withdraw  tokens from LevelsVault.
  function withdraw(uint256 _pid, uint256 _amount) public {
    _withdraw(_pid, _amount, msg.sender, msg.sender);
  }

  // Low level withdraw function
  function _withdraw(uint256 _pid, uint256 _amount, address from, address to) internal {
    PoolInfo storage pool = poolInfo[_pid];
    require(pool.withdrawable, "Withdrawing from this pool is disabled");
    UserInfo storage user = userInfo[_pid][from];
    require(user.amount >= _amount, "withdraw: not good");

    massUpdatePools();
    updateAndPayOutPending(_pid, from); // Update balances of from this is not withdrawal but claiming CORE farmed

    if(_amount > 0) {
      user.amount = user.amount.sub(_amount);
      pool.token.safeTransfer(address(to), _amount);
    }
    user.rewardDebt = user.amount.mul(pool.accLevelsPerShare).div(1e12);

    emit Withdraw(to, _pid, _amount);
  }
  function updateAndPayOutPending(uint256 _pid, address from) internal {
    uint256 pending = pendingLevels(_pid, from);

    if(pending > 0) {
      safeLevelsTransfer(from, pending);
    }

  }


  // function that lets owner/governance contract
  // approve allowance for any token inside this contract
  // This means all future UNI like airdrops are covered
  // And at the same time allows us to give allowance to strategy contracts.
  // Upcoming cYFI etc vaults strategy contracts will  se this function to manage and farm yield on value locked
  function setStrategyContractOrDistributionContractAllowance(address tokenAddress, uint256 _amount, address contractAddress) public onlySuperAdmin {
    require(isContract(contractAddress), "Recipent is not a smart contract, BAD");
    require(block.number > contractStartBlock.add(95_000), "Governance setup grace period not over"); // about 2weeks
    IERC20(tokenAddress).approve(contractAddress, _amount);
  }

  function isContract(address addr) public returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    require(pool.withdrawable, "Withdrawing from this pool is disabled");
    UserInfo storage user = userInfo[_pid][msg.sender];
    pool.token.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
    // No mass update dont update pending rewards
  }

  // Safe LEVELS transfer function, just in case if rounding error causes pool to not have enough LEVELS.
  function safeLevelsTransfer(address _to, uint256 _amount) internal {
    if(_amount == 0) return;
    uint256 levelsBal = levels.balanceOf(address(this));

    if (_amount > levelsBal) {
      levels.transfer(_to, levelsBal);
      levelsBalance = levels.balanceOf(address(this));
    } else {
      levels.transfer(_to, _amount);
      levelsBalance = levels.balanceOf(address(this));
    }

    transferDevFee();
  }

  // For migration purpose only!
  function migrateAssets() public onlyOwner {
    uint256 levelsBal = levels.balanceOf(address(this));
    if(levelsBal == 0)  return;

    levels.transfer(msg.sender, levelsBal);
  }

  function transferDevFee() public {
    if(pending_DEV_rewards == 0) return;

    uint256 levelsBal = levels.balanceOf(address(this));
    if (pending_DEV_rewards > levelsBal) {

      levels.transfer(devaddr, levelsBal);
      levelsBalance = levels.balanceOf(address(this));

    } else {

      levels.transfer(devaddr, pending_DEV_rewards);
      levelsBalance = levels.balanceOf(address(this));

    }

    pending_DEV_rewards = 0;
  }

  // Update dev address by the previous dev.
  // Note onlyOwner functions are meant for the governance contract
  // allowing LEVELS governance token holders to do this functions.
  function setDevFeeReciever(address _devaddr) public onlyOwner {
    devaddr = _devaddr;
  }

  address private _superAdmin;

  event SuperAdminTransfered(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Returns the address of the current super admin
   */
  function superAdmin() public view returns (address) {
    return _superAdmin;
  }

  /**
   * @dev Throws if called by any account other than the superAdmin
   */
  modifier onlySuperAdmin() {
    require(_superAdmin == _msgSender(), "Super admin : caller is not super admin.");
    _;
  }

  // Assisns super admint to address 0, making it unreachable forever
  function burnSuperAdmin() public virtual onlySuperAdmin {
    emit SuperAdminTransfered(_superAdmin, address(0));
    _superAdmin = address(0);
  }

  // Super admin can transfer its powers to another address
  function newSuperAdmin(address newOwner) public virtual onlySuperAdmin {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit SuperAdminTransfered(_superAdmin, newOwner);
    _superAdmin = newOwner;
  }
}
