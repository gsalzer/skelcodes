// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

import "./AttoDecimal.sol";
import "./IStakingPoolMigrator.sol";
import "./TwoStageOwnable.sol";

contract StakingPool is ERC20, ReentrancyGuard, TwoStageOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using AttoDecimalLib for AttoDecimal;

    struct Strategy {
        uint256 endBlockNumber;
        uint256 perBlockReward;
        uint256 startBlockNumber;
    }

    struct Unstake {
        uint256 amount;
        uint256 applicableAt;
    }

    uint256 public constant MIN_STAKE_BALANCE = 10**18;
    bool public migratorInitialized;

    uint256 public claimingFeePercent;
    uint256 public lastUpdateBlockNumber;

    IStakingPoolMigrator public migrator;

    uint256 private _feePool;
    uint256 private _lockedRewards;
    uint256 private _totalStaked;
    uint256 private _totalUnstaked;
    uint256 private _unstakingTime;
    IERC20 private _stakingToken;

    AttoDecimal private _DEFAULT_PRICE;
    AttoDecimal private _price;
    Strategy private _currentStrategy;
    Strategy private _nextStrategy;

    mapping(address => Unstake) private _unstakes;

    function getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    function getTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function feePool() public view returns (uint256) {
        return _feePool;
    }

    function lockedRewards() public view returns (uint256) {
        return _lockedRewards;
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function totalUnstaked() public view returns (uint256) {
        return _totalUnstaked;
    }

    function stakingToken() public view returns (IERC20) {
        return _stakingToken;
    }

    function unstakingTime() public view returns (uint256) {
        return _unstakingTime;
    }

    function currentStrategy() public view returns (Strategy memory) {
        return _currentStrategy;
    }

    function nextStrategy() public view returns (Strategy memory) {
        return _nextStrategy;
    }

    function getUnstake(address account) public view returns (Unstake memory result) {
        result = _unstakes[account];
    }

    function DEFAULT_PRICE()
        external
        view
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return _DEFAULT_PRICE.toTuple();
    }

    function getCurrentStrategyUnlockedRewards() public view returns (uint256 unlocked) {
        unlocked = _getStrategyUnlockedRewards(_currentStrategy);
    }

    function getUnlockedRewards() public view returns (uint256 unlocked, bool currentStrategyEnded) {
        unlocked = _getStrategyUnlockedRewards(_currentStrategy);
        if (_currentStrategy.endBlockNumber != 0 && getBlockNumber() >= _currentStrategy.endBlockNumber) {
            currentStrategyEnded = true;
            unlocked = unlocked.add(_getStrategyUnlockedRewards(_nextStrategy));
        }
    }

    /// @notice Calculates price of synthetic token for current block
    function price()
        public
        view
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        (uint256 unlocked, ) = getUnlockedRewards();
        uint256 totalStaked_ = _totalStaked;
        uint256 totalSupply_ = totalSupply();
        if (migratorInitialized) {
            (uint256 stakingPoolV1Balance, uint256 burnedSyntheticAmount) = migrator.calculatePriceParams();
            totalStaked_ = totalStaked_.add(stakingPoolV1Balance);
            totalSupply_ = totalSupply_.sub(burnedSyntheticAmount);
        }
        AttoDecimal memory result;
        if (totalSupply_ == 0) result = _DEFAULT_PRICE;
        else result = AttoDecimalLib.div(totalStaked_.add(unlocked), totalSupply_);
        return (result.mantissa, AttoDecimalLib.BASE, AttoDecimalLib.EXPONENTIATION);
    }

    /// @notice Returns last updated price of synthetic token
    function priceStored()
        public
        view
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return (_price.mantissa, AttoDecimalLib.BASE, AttoDecimalLib.EXPONENTIATION);
    }

    /// @notice Calculates expected result of swapping synthetic tokens for OM tokens
    /// @param account Account that wants to swap
    /// @param amount Minimum amount of OM tokens that should be received at swapping process
    /// @return unstakedAmount Amount of OM tokens that should be received at swapping process
    /// @return burnedAmount Amount of synthetic tokens that should be burned at swapping process
    function calculateUnstake(address account, uint256 amount)
        public
        view
        returns (uint256 unstakedAmount, uint256 burnedAmount)
    {
        (uint256 mantissa_, , ) = price();
        return _calculateUnstake(account, amount, AttoDecimal(mantissa_));
    }

    event Claimed(
        address indexed account,
        uint256 requestedAmount,
        uint256 claimedAmount,
        uint256 feeAmount,
        uint256 burnedAmount
    );

    event CurrentStrategyUpdated(uint256 perBlockReward, uint256 startBlockNumber, uint256 endBlockNumber);
    event FeeClaimed(address indexed receiver, uint256 amount);

    event Migrated(
        address indexed account,
        uint256 omTokenV1StakeAmount,
        uint256 stakingPoolV1Reward,
        uint256 stakingPoolV2Reward
    );

    event MigratorInitialized();
    event MigratorUpdated(address indexed migrator);
    event NextStrategyUpdated(uint256 perBlockReward, uint256 startBlockNumber, uint256 endBlockNumber);
    event UnstakingTimeUpdated(uint256 unstakingTime);
    event NextStrategyRemoved();
    event PoolIncreased(address indexed payer, uint256 amount);
    event PriceUpdated(uint256 mantissa, uint256 base, uint256 exponentiation);
    event RewardsUnlocked(uint256 amount);
    event Staked(address indexed account, address indexed payer, uint256 stakedAmount, uint256 mintedAmount);
    event Unstaked(address indexed account, uint256 requestedAmount, uint256 unstakedAmount, uint256 burnedAmount);
    event UnstakingCanceled(address indexed account, uint256 amount);
    event Withdrawed(address indexed account, uint256 amount);

    constructor(
        string memory syntheticTokenName,
        string memory syntheticTokenSymbol,
        IERC20 stakingToken_,
        address owner_,
        uint256 claimingFeePercent_,
        uint256 perBlockReward_,
        uint256 startBlockNumber_,
        uint256 duration_,
        uint256 unstakingTime_,
        uint256 defaultPriceMantissa
    ) public TwoStageOwnable(owner_) ERC20(syntheticTokenName, syntheticTokenSymbol) {
        _DEFAULT_PRICE = AttoDecimal(defaultPriceMantissa);
        _stakingToken = stakingToken_;
        _setClaimingFeePercent(claimingFeePercent_);
        _validateStrategyParameters(perBlockReward_, startBlockNumber_, duration_);
        _setUnstakingTime(unstakingTime_);
        _setCurrentStrategy(perBlockReward_, startBlockNumber_, startBlockNumber_.add(duration_));
        lastUpdateBlockNumber = getBlockNumber();
        _price = _DEFAULT_PRICE;
    }

    /// @notice Burns synthetic tokens. May be called only by migrator contract
    /// @param amount Synthetic tokens amount to be burned
    function burn(uint256 amount) external onlyMigrator returns (bool success) {
        _burn(msg.sender, amount);
        return true;
    }

    /// @notice Cancels unstaking by staking locked for withdrawals tokens
    /// @param amount Amount of locked for withdrawals tokens
    function cancelUnstaking(uint256 amount) external onlyPositiveAmount(amount) returns (bool success) {
        _update();
        address caller = msg.sender;
        Unstake storage unstake_ = _unstakes[caller];
        uint256 unstakingAmount = unstake_.amount;
        require(unstakingAmount >= amount, "Not enough unstaked balance");
        uint256 stakedAmount = _price.mul(balanceOf(caller)).floor();
        require(
            stakedAmount.add(amount) >= MIN_STAKE_BALANCE,
            "Resulting stake balance less than minimal stake balance"
        );
        uint256 synthAmount = AttoDecimalLib.div(amount, _price).floor();
        _mint(caller, synthAmount);
        _totalStaked = _totalStaked.add(amount);
        _totalUnstaked = _totalUnstaked.sub(amount);
        unstake_.amount = unstakingAmount.sub(amount);
        emit Staked(caller, address(0), amount, synthAmount);
        emit UnstakingCanceled(caller, amount);
        return true;
    }

    /// @notice Swaps synthetic tokens for OM tokens and immediately sends them to the caller but takes some fee
    /// @param amount OM tokens amount to swap for. Fee will be taked from this amount
    /// @return claimedAmount Amount of OM tokens that was been sended to caller
    /// @return burnedAmount Amount of synthetic tokens that was burned while swapping
    function claim(uint256 amount)
        external
        onlyPositiveAmount(amount)
        returns (uint256 claimedAmount, uint256 burnedAmount)
    {
        _update();
        address caller = msg.sender;
        (claimedAmount, burnedAmount) = _calculateUnstake(caller, amount, _price);
        uint256 fee = claimedAmount.mul(claimingFeePercent).div(100);
        _burn(caller, burnedAmount);
        _totalStaked = _totalStaked.sub(claimedAmount);
        claimedAmount = claimedAmount.sub(fee);
        _feePool = _feePool.add(fee);
        emit Claimed(caller, amount, claimedAmount, fee, burnedAmount);
        _stakingToken.safeTransfer(caller, claimedAmount);
    }

    /// @notice Withdraws all OM tokens, that have been accumulated in imidiatly claiming process.
    ///     Allowed to be called only by the owner
    /// @return amount Amount of accumulated and withdrawed tokens
    function claimFees() external onlyOwner returns (uint256 amount) {
        require(_feePool > 0, "No fees");
        amount = _feePool;
        _feePool = 0;
        emit FeeClaimed(owner, amount);
        _stakingToken.safeTransfer(owner, amount);
    }

    /// @notice Creates new strategy. Allowed to be called only by the owner
    /// @param perBlockReward_ Reward that should be added to common OM tokens pool every block
    /// @param startBlockNumber_ Number of block from which strategy should starts
    /// @param duration_ Blocks count for which new strategy should be applied
    function createNewStrategy(
        uint256 perBlockReward_,
        uint256 startBlockNumber_,
        uint256 duration_
    ) public onlyOwner returns (bool success) {
        _update();
        _validateStrategyParameters(perBlockReward_, startBlockNumber_, duration_);
        uint256 endBlockNumber = startBlockNumber_.add(duration_);
        Strategy memory strategy =
            Strategy({
                perBlockReward: perBlockReward_,
                startBlockNumber: startBlockNumber_,
                endBlockNumber: endBlockNumber
            });
        if (_currentStrategy.startBlockNumber > getBlockNumber()) {
            delete _nextStrategy;
            emit NextStrategyRemoved();
            _currentStrategy = strategy;
            emit CurrentStrategyUpdated(perBlockReward_, startBlockNumber_, endBlockNumber);
        } else {
            emit NextStrategyUpdated(perBlockReward_, startBlockNumber_, endBlockNumber);
            _nextStrategy = strategy;
            if (_currentStrategy.endBlockNumber > startBlockNumber_) {
                _currentStrategy.endBlockNumber = startBlockNumber_;
                emit CurrentStrategyUpdated(
                    _currentStrategy.perBlockReward,
                    _currentStrategy.startBlockNumber,
                    startBlockNumber_
                );
            }
        }
        return true;
    }

    /// @notice Increases pool of rewards
    /// @param amount Amount of OM tokens (in wei) that should be added to rewards pool
    function increasePool(uint256 amount) external onlyPositiveAmount(amount) returns (bool success) {
        _update();
        address payer = msg.sender;
        _lockedRewards = _lockedRewards.add(amount);
        emit PoolIncreased(payer, amount);
        _stakingToken.safeTransferFrom(payer, address(this), amount);
        return true;
    }

    /// @notice Method may be called only by nominated migrator contract. Sets caller as a migrator
    function initializeMigrator() external returns (bool success) {
        _update();
        assertCallerIsMigrator();
        migratorInitialized = true;
        emit MigratorInitialized();
        return true;
    }

    /// @notice Mints requested amount of synthetic tokens to specific account.
    ///     This method can be called only by migrator
    /// @param account Address for which synthetic tokens should be minted
    /// @param amount Amount of synthetic tokens to be minted
    function mint(address account, uint256 amount) external onlyMigrator returns (bool success) {
        _mint(account, amount);
        return true;
    }

    /// @notice Nominates some contract to the migrator role. Method allowed to be called only by the owner
    /// @param migrator_ Address of migration contract to be nominated
    function setMigrator(IStakingPoolMigrator migrator_) external onlyOwner returns (bool success) {
        require(!migratorInitialized, "Migrator already initialized");
        migrator = migrator_;
        emit MigratorUpdated(address(migrator_));
        return true;
    }

    /// @notice Converts OM tokens to synthetic tokens
    /// @param amount Amount of OM tokens to be swapped
    /// @return mintedAmount Amount of synthetic tokens that was received at swapping process
    function stake(uint256 amount) external onlyPositiveAmount(amount) returns (uint256 mintedAmount) {
        address staker = msg.sender;
        return _stake(staker, staker, amount);
    }

    /// @notice Converts OM tokens to synthetic tokens and sends them to specific account
    /// @param account Receiver of synthetic tokens
    /// @param amount Amount of OM tokens to be swapped
    /// @return mintedAmount Amount of synthetic tokens that was received by specified account at swapping process
    function stakeForUser(address account, uint256 amount)
        external
        onlyPositiveAmount(amount)
        returns (uint256 mintedAmount)
    {
        return _stake(account, msg.sender, amount);
    }

    /// @notice Moves locked for rewards OM tokens to OM tokens pool. Allowed to be called only by migrator contract
    /// @param amount Amount of OM tokens to be unlocked
    /// @dev Will cause price increasing from next block
    function unlockRewards(uint256 amount) external onlyMigrator returns (bool success) {
        _lockedRewards = _lockedRewards.sub(amount, "Reward pool is extinguished");
        _totalStaked = _totalStaked.add(amount);
        emit RewardsUnlocked(amount);
        return true;
    }

    /// @notice Swapes synthetic tokens for OM tokens and locks them for some period
    /// @param amount Minimum amount of OM tokens that should be locked after swapping process
    /// @return unstakedAmount Amount of OM tokens that was locked
    /// @return burnedAmount Amount of synthetic tokens that was burned
    function unstake(uint256 amount)
        external
        onlyPositiveAmount(amount)
        returns (uint256 unstakedAmount, uint256 burnedAmount)
    {
        _update();
        address caller = msg.sender;
        (unstakedAmount, burnedAmount) = _calculateUnstake(caller, amount, _price);
        _burn(caller, burnedAmount);
        _totalStaked = _totalStaked.sub(unstakedAmount);
        _totalUnstaked = _totalUnstaked.add(unstakedAmount);
        Unstake storage unstake_ = _unstakes[caller];
        unstake_.amount = unstake_.amount.add(unstakedAmount);
        unstake_.applicableAt = getTimestamp().add(_unstakingTime);
        emit Unstaked(caller, amount, unstakedAmount, burnedAmount);
    }

    /// @notice Swapes migrator's synthetic tokens for OM tokens and imidiatly sends them.
    ///     Allowed to be called only by migrator contract
    /// @param amount Amount of OM tokens that should be received from swapping process
    /// @return synthToBurn Amount of burned synthetic tokens
    function unstakeLocked(uint256 amount) external onlyMigrator returns (uint256 synthToBurn) {
        _update();
        synthToBurn = AttoDecimalLib.div(amount, _price).floor();
        _burn(address(migrator), synthToBurn);
        _totalStaked = _totalStaked.sub(amount, "Not enough staked OM amount");
        _stakingToken.safeTransfer(address(migrator), amount);
    }

    /// @notice Updates price of synthetic token
    /// @dev Automatically has been called on every contract action, that uses or can affect price
    function update() external returns (bool success) {
        _update();
        return true;
    }

    /// @notice Withdraws unstaked OM tokens
    function withdraw() external returns (bool success) {
        address caller = msg.sender;
        Unstake storage unstake_ = _unstakes[caller];
        uint256 amount = unstake_.amount;
        require(amount > 0, "Not unstaked");
        require(unstake_.applicableAt <= getTimestamp(), "Not released at");
        delete _unstakes[caller];
        _totalUnstaked = _totalUnstaked.sub(amount);
        emit Withdrawed(caller, amount);
        _stakingToken.safeTransfer(caller, amount);
        return true;
    }

    /// @notice Change unstaking time. Can be called only by the owner
    /// @param unstakingTime_ New unstaking process duration in seconds
    function setUnstakingTime(uint256 unstakingTime_) external onlyOwner returns (bool success) {
        _setUnstakingTime(unstakingTime_);
        return true;
    }

    function _getStrategyUnlockedRewards(Strategy memory strategy_) internal view returns (uint256 unlocked) {
        uint256 currentBlockNumber = getBlockNumber();
        if (currentBlockNumber < strategy_.startBlockNumber || currentBlockNumber == lastUpdateBlockNumber) {
            return unlocked;
        }
        uint256 lastRewardedBlockNumber = Math.max(lastUpdateBlockNumber, strategy_.startBlockNumber);
        uint256 lastRewardableBlockNumber = Math.min(currentBlockNumber, strategy_.endBlockNumber);
        if (lastRewardedBlockNumber < lastRewardableBlockNumber) {
            uint256 blocksDiff = lastRewardableBlockNumber.sub(lastRewardedBlockNumber);
            unlocked = unlocked.add(blocksDiff.mul(strategy_.perBlockReward));
        }
    }

    function _calculateUnstake(
        address account,
        uint256 amount,
        AttoDecimal memory price_
    ) internal view returns (uint256 unstakedAmount, uint256 burnedAmount) {
        unstakedAmount = amount;
        burnedAmount = AttoDecimalLib.div(amount, price_).ceil();
        uint256 balance = balanceOf(account);
        require(burnedAmount > 0, "Too small unstaking amount");
        require(balance >= burnedAmount, "Not enough synthetic tokens");
        uint256 remainingSyntheticBalance = balance.sub(burnedAmount);
        uint256 remainingStake = _price.mul(remainingSyntheticBalance).floor();
        if (remainingStake < 10**18) {
            burnedAmount = balance;
            unstakedAmount = unstakedAmount.add(remainingStake);
        }
    }

    function _unlockRewardsAndStake() internal {
        (uint256 unlocked, bool currentStrategyEnded) = getUnlockedRewards();
        if (currentStrategyEnded) {
            _currentStrategy = _nextStrategy;
            emit NextStrategyRemoved();
            if (_currentStrategy.endBlockNumber != 0) {
                emit CurrentStrategyUpdated(
                    _currentStrategy.perBlockReward,
                    _currentStrategy.startBlockNumber,
                    _currentStrategy.endBlockNumber
                );
            }
            delete _nextStrategy;
        }
        unlocked = Math.min(unlocked, _lockedRewards);
        if (unlocked > 0) {
            emit RewardsUnlocked(unlocked);
            _lockedRewards = _lockedRewards.sub(unlocked);
            _totalStaked = _totalStaked.add(unlocked);
        }
        lastUpdateBlockNumber = getBlockNumber();
    }

    function _update() internal {
        if (getBlockNumber() <= lastUpdateBlockNumber) return;
        if (migratorInitialized) migrator.update();
        _unlockRewardsAndStake();
        _updatePrice();
    }

    function _updatePrice() internal {
        uint256 totalStaked_ = _totalStaked;
        uint256 totalSupply_ = totalSupply();
        if (migratorInitialized) totalStaked_ = totalStaked_.add(migrator.stakingPoolV1Balance());
        if (totalSupply_ == 0) _price = _DEFAULT_PRICE;
        else _price = AttoDecimalLib.div(totalStaked_, totalSupply_);
        emit PriceUpdated(_price.mantissa, AttoDecimalLib.BASE, AttoDecimalLib.EXPONENTIATION);
    }

    function _validateStrategyParameters(
        uint256 perBlockReward,
        uint256 startBlockNumber,
        uint256 duration
    ) internal view {
        require(duration > 0, "Duration is zero");
        require(startBlockNumber >= getBlockNumber(), "Start block number less then current");
        require(perBlockReward <= 188 * 10**18, "Per block reward overflow");
    }

    function _setClaimingFeePercent(uint256 feePercent) internal {
        require(feePercent >= 0 && feePercent <= 100, "Percent fee should be in range [0; 100]");
        claimingFeePercent = feePercent;
    }

    function _setUnstakingTime(uint256 unstakingTime_) internal {
        _unstakingTime = unstakingTime_;
        emit UnstakingTimeUpdated(unstakingTime_);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (msg.sender == address(migrator)) return;
        _update();
        string memory errorText = "Minimal stake balance should be more or equal to 1 token";
        if (from != address(0)) {
            uint256 fromNewBalance = _price.mul(balanceOf(from).sub(amount)).floor();
            require(fromNewBalance >= MIN_STAKE_BALANCE || fromNewBalance == 0, errorText);
        }
        if (to != address(0)) {
            require(_price.mul(balanceOf(to).add(amount)).floor() >= MIN_STAKE_BALANCE, errorText);
        }
    }

    function _setCurrentStrategy(
        uint256 perBlockReward_,
        uint256 startBlockNumber_,
        uint256 endBlockNumber_
    ) private {
        _currentStrategy = Strategy({
            perBlockReward: perBlockReward_,
            startBlockNumber: startBlockNumber_,
            endBlockNumber: endBlockNumber_
        });
        emit CurrentStrategyUpdated(perBlockReward_, startBlockNumber_, endBlockNumber_);
    }

    function _stake(
        address staker,
        address payer,
        uint256 amount
    ) private returns (uint256 mintedAmount) {
        _update();
        mintedAmount = AttoDecimalLib.div(amount, _price).floor();
        require(mintedAmount > 0, "Too small staking amount");
        _mint(staker, mintedAmount);
        _totalStaked = _totalStaked.add(amount);
        emit Staked(staker, payer, amount, mintedAmount);
        _stakingToken.safeTransferFrom(payer, address(this), amount);
    }

    function assertCallerIsMigrator() internal view {
        require(msg.sender == address(migrator), "Allowed only by migrator");
    }

    modifier onlyMigrator() {
        assertCallerIsMigrator();
        require(migratorInitialized, "Migrator not initialized");
        _;
    }

    modifier onlyPositiveAmount(uint256 amount) {
        require(amount > 0, "Amount is not positive");
        _;
    }
}

