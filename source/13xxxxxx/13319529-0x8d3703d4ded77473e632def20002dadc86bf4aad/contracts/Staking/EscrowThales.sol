pragma solidity ^0.5.16;

import "openzeppelin-solidity-2.3.0/contracts/math/Math.sol";
import "synthetix-2.43.1/contracts/SafeDecimalMath.sol";
import "openzeppelin-solidity-2.3.0/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity-2.3.0/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity-2.3.0/contracts/utils/ReentrancyGuard.sol";
import "synthetix-2.43.1/contracts/Pausable.sol";
import "../interfaces/IEscrowThales.sol";
import "../interfaces/IStakingThales.sol";

contract EscrowThales is IEscrowThales, Owned, ReentrancyGuard, Pausable {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public vestingToken;
    IStakingThales public iStakingThales;
    address public airdropContract;

    uint public constant NUM_PERIODS = 10;
    uint public totalEscrowedRewards = 0;
    uint public totalEscrowBalanceNotIncludedInStaking = 0;
    uint public currentVestingPeriod = 0;

    uint private _totalVested = 0;

    struct VestingEntry {
        uint amount;
        uint vesting_period;
    }

    mapping(address => VestingEntry[NUM_PERIODS]) public vestingEntries;
    mapping(address => uint) public totalAccountEscrowedAmount;

    mapping(address => uint) public lastPeriodAddedReward;

    bool private testMode = false;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _vestingToken //THALES
    ) public Owned(_owner) {
        vestingToken = IERC20(_vestingToken);
    }

    function getStakerPeriod(address account, uint index) external view returns (uint) {
        require(account != address(0), "Invalid account address");
        return vestingEntries[account][index].vesting_period;
    }

    function getStakerAmounts(address account, uint index) external view returns (uint) {
        require(account != address(0), "Invalid account address");
        return vestingEntries[account][index].amount;
    }

    function getStakedEscrowedBalanceForRewards(address account) external view returns (uint) {
        if (lastPeriodAddedReward[account] == currentVestingPeriod) {
            return
                totalAccountEscrowedAmount[account].sub(
                    vestingEntries[account][currentVestingPeriod.mod(NUM_PERIODS)].amount
                );
        } else {
            return totalAccountEscrowedAmount[account];
        }
    }

    function claimable(address account) external view returns (uint) {
        require(account != address(0), "Invalid address");
        return totalAccountEscrowedAmount[account].sub(_getVestingNotAvailable(account));
    }

    function addToEscrow(address account, uint amount) external {
        require(account != address(0), "Invalid address");
        require(amount > 0, "Amount is 0");
        require(
            msg.sender == address(iStakingThales) || msg.sender == airdropContract,
            "Add to escrow can only be called from staking or ongoing airdrop contracts"
        );

        totalAccountEscrowedAmount[account] = totalAccountEscrowedAmount[account].add(amount);

        lastPeriodAddedReward[account] = currentVestingPeriod;

        vestingEntries[account][currentVestingPeriod.mod(NUM_PERIODS)].amount = amount;
        vestingEntries[account][currentVestingPeriod.mod(NUM_PERIODS)].vesting_period = currentVestingPeriod.add(
            NUM_PERIODS
        );

        totalEscrowedRewards = totalEscrowedRewards.add(amount);
        //Transfering THALES from StakingThales to EscrowThales
        vestingToken.safeTransferFrom(msg.sender, address(this), amount);

        // add to totalEscrowBalanceNotIncludedInStaking if user is not staking
        if (iStakingThales.stakedBalanceOf(account) == 0) {
            totalEscrowBalanceNotIncludedInStaking = totalEscrowBalanceNotIncludedInStaking.add(amount);
        }

        emit AddedToEscrow(account, amount);
    }

    function vest(uint amount) external nonReentrant notPaused returns (bool) {
        require(amount > 0, "Claimed amount is 0");
        require(currentVestingPeriod > NUM_PERIODS, "Vesting rewards still not available");

        uint vestingAmount = 0;
        vestingAmount = totalAccountEscrowedAmount[msg.sender].sub(_getVestingNotAvailable(msg.sender));
        // Amount must be lower than the reward
        require(amount <= vestingAmount, "Amount exceeds the claimable rewards");
        totalAccountEscrowedAmount[msg.sender] = totalAccountEscrowedAmount[msg.sender].sub(amount);
        totalEscrowedRewards = totalEscrowedRewards.sub(amount);
        _totalVested = _totalVested.add(amount);
        vestingToken.safeTransfer(msg.sender, amount);

        // subtract from totalEscrowBalanceNotIncludedInStaking if user is not staking
        if (iStakingThales.stakedBalanceOf(msg.sender) == 0) {
            totalEscrowBalanceNotIncludedInStaking = totalEscrowBalanceNotIncludedInStaking.sub(amount);
        }

        emit Vested(msg.sender, amount);
        return true;
    }

    function addTotalEscrowBalanceNotIncludedInStaking(uint amount) external {
        require(msg.sender == address(iStakingThales), "Can only be called from staking contract");
        totalEscrowBalanceNotIncludedInStaking = totalEscrowBalanceNotIncludedInStaking.add(amount);
    }

    function subtractTotalEscrowBalanceNotIncludedInStaking(uint amount) external {
        require(msg.sender == address(iStakingThales), "Can only be called from staking contract");
        totalEscrowBalanceNotIncludedInStaking = totalEscrowBalanceNotIncludedInStaking.sub(amount);
    }

    function updateCurrentPeriod() external returns (bool) {
        if (!testMode) {
            require(msg.sender == address(iStakingThales), "Can only be called from staking contract");
        }
        currentVestingPeriod = currentVestingPeriod.add(1);
        return true;
    }

    function setStakingThalesContract(address StakingThalesContract) external onlyOwner {
        require(StakingThalesContract != address(0), "Invalid address set");
        iStakingThales = IStakingThales(StakingThalesContract);
        emit StakingThalesContractChanged(StakingThalesContract);
    }

    function enableTestMode() external onlyOwner {
        testMode = true;
    }

    function setAirdropContract(address AirdropContract) external onlyOwner {
        require(AirdropContract != address(0), "Invalid address set");
        airdropContract = AirdropContract;
        emit AirdropContractChanged(AirdropContract);
    }

    function selfDestruct(address payable account) external onlyOwner {
        vestingToken.safeTransfer(account, vestingToken.balanceOf(address(this)));
        selfdestruct(account);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _getVestingNotAvailable(address account) internal view returns (uint) {
        uint vesting_not_available = 0;
        for (uint i = 0; i < NUM_PERIODS; i++) {
            if (vestingEntries[account][i].vesting_period >= currentVestingPeriod) {
                vesting_not_available = vesting_not_available.add(vestingEntries[account][i].amount);
            }
        }
        return vesting_not_available;
    }

    /* ========== EVENTS ========== */

    event AddedToEscrow(address acount, uint amount);
    event Vested(address account, uint amount);
    event StakingThalesContractChanged(address newAddress);
    event AirdropContractChanged(address newAddress);
}

