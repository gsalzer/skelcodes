// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IComitium.sol";
import "../libraries/LibComitiumStorage.sol";
import "../libraries/LibOwnership.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ComitiumFacet {
    using SafeMath for uint256;

    uint256 constant public MAX_LOCK = 365 days;
    uint256 constant BASE_MULTIPLIER = 1e18;

    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    event Withdraw(address indexed user, uint256 amountWithdrew, uint256 amountLeft);
    event Lock(address indexed user, uint256 timestamp);
    event Delegate(address indexed from, address indexed to);
    event DelegatedPowerIncreased(address indexed from, address indexed to, uint256 amount, uint256 to_newDelegatedPower);
    event DelegatedPowerDecreased(address indexed from, address indexed to, uint256 amount, uint256 to_newDelegatedPower);

    function initComitium(address _fdt, address _rewards) public {
        require(_fdt != address(0), "FDT address must not be 0x0");

        LibComitiumStorage.Storage storage ds = LibComitiumStorage.comitiumStorage();

        require(!ds.initialized, "Comitium: already initialized");
        LibOwnership.enforceIsContractOwner();

        ds.initialized = true;

        ds.fdt = IERC20(_fdt);
        ds.rewards = IRewards(_rewards);
    }

    // deposit allows a user to add more fdt to his staked balance
    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");

       LibComitiumStorage.Storage storage ds = LibComitiumStorage.comitiumStorage();
        uint256 allowance = ds.fdt.allowance(msg.sender, address(this));
        require(allowance >= amount, "Token allowance too small");

        // this must be called before the user's balance is updated so the rewards contract can calculate
        // the amount owed correctly
        if (address(ds.rewards) != address(0)) {
            ds.rewards.registerUserAction(msg.sender);
        }

        uint256 newBalance = balanceOf(msg.sender).add(amount);
        _updateUserBalance(ds.userStakeHistory[msg.sender], newBalance);
        _updateLockedFdt(fdtStakedAtTs(block.timestamp).add(amount));

        address delegatedTo = userDelegatedTo(msg.sender);
        if (delegatedTo != address(0)) {
            uint256 newDelegatedPower = delegatedPower(delegatedTo).add(amount);
            _updateDelegatedPower(ds.delegatedPowerHistory[delegatedTo], newDelegatedPower);

            emit DelegatedPowerIncreased(msg.sender, delegatedTo, amount, newDelegatedPower);
        }
        ds.fdt.transferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount, newBalance);
    }

    // withdraw allows a user to withdraw funds if the balance is not locked
    function withdraw(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(userLockedUntil(msg.sender) <= block.timestamp, "User balance is locked");

        uint256 balance = balanceOf(msg.sender);
        require(balance >= amount, "Insufficient balance");

        LibComitiumStorage.Storage storage ds = LibComitiumStorage.comitiumStorage();

        // this must be called before the user's balance is updated so the rewards contract can calculate
        // the amount owed correctly
        if (address(ds.rewards) != address(0)) {
            ds.rewards.registerUserAction(msg.sender);
        }

        _updateUserBalance(ds.userStakeHistory[msg.sender], balance.sub(amount));
        _updateLockedFdt(fdtStakedAtTs(block.timestamp).sub(amount));

        address delegatedTo = userDelegatedTo(msg.sender);
        if (delegatedTo != address(0)) {
            uint256 newDelegatedPower = delegatedPower(delegatedTo).sub(amount);
            _updateDelegatedPower(ds.delegatedPowerHistory[delegatedTo], newDelegatedPower);

            emit DelegatedPowerDecreased(msg.sender, delegatedTo, amount, newDelegatedPower);
        }

        ds.fdt.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount, balance.sub(amount));
    }

    // lock a user's currently staked balance until timestamp & add the bonus to his voting power
    function lock(uint256 timestamp) public {
        require(timestamp > block.timestamp, "Timestamp must be in the future");
        require(timestamp <= block.timestamp + MAX_LOCK, "Timestamp too big");
        require(balanceOf(msg.sender) > 0, "Sender has no balance");

        LibComitiumStorage.Storage storage ds = LibComitiumStorage.comitiumStorage();
        LibComitiumStorage.Stake[] storage checkpoints = ds.userStakeHistory[msg.sender];
        LibComitiumStorage.Stake storage currentStake = checkpoints[checkpoints.length - 1];

        require(timestamp > currentStake.expiryTimestamp, "New timestamp lower than current lock timestamp");

        _updateUserLock(checkpoints, timestamp);

        emit Lock(msg.sender, timestamp);
    }

    function depositAndLock(uint256 amount, uint256 timestamp) public {
        deposit(amount);
        lock(timestamp);
    }

    // delegate allows a user to delegate his voting power to another user
    function delegate(address to) public {
        require(msg.sender != to, "Can't delegate to self");

        uint256 senderBalance = balanceOf(msg.sender);
        require(senderBalance > 0, "No balance to delegate");

        LibComitiumStorage.Storage storage ds = LibComitiumStorage.comitiumStorage();

        emit Delegate(msg.sender, to);

        address delegatedTo = userDelegatedTo(msg.sender);
        if (delegatedTo != address(0)) {
            uint256 newDelegatedPower = delegatedPower(delegatedTo).sub(senderBalance);
            _updateDelegatedPower(ds.delegatedPowerHistory[delegatedTo], newDelegatedPower);

            emit DelegatedPowerDecreased(msg.sender, delegatedTo, senderBalance, newDelegatedPower);
        }

        if (to != address(0)) {
            uint256 newDelegatedPower = delegatedPower(to).add(senderBalance);
            _updateDelegatedPower(ds.delegatedPowerHistory[to], newDelegatedPower);

            emit DelegatedPowerIncreased(msg.sender, to, senderBalance, newDelegatedPower);
        }

        _updateUserDelegatedTo(ds.userStakeHistory[msg.sender], to);
    }

    // stopDelegate allows a user to take back the delegated voting power
    function stopDelegate() public {
        return delegate(address(0));
    }

    // balanceOf returns the current FDT balance of a user (bonus not included)
    function balanceOf(address user) public view returns (uint256) {
        return balanceAtTs(user, block.timestamp);
    }

    // balanceAtTs returns the amount of FDT that the user currently staked (bonus NOT included)
    function balanceAtTs(address user, uint256 timestamp) public view returns (uint256) {
        LibComitiumStorage.Stake memory stake = stakeAtTs(user, timestamp);

        return stake.amount;
    }

    // stakeAtTs returns the Stake object of the user that was valid at `timestamp`
    function stakeAtTs(address user, uint256 timestamp) public view returns (LibComitiumStorage.Stake memory) {
        LibComitiumStorage.Storage storage ds = LibComitiumStorage.comitiumStorage();
        LibComitiumStorage.Stake[] storage stakeHistory = ds.userStakeHistory[user];

        if (stakeHistory.length == 0 || timestamp < stakeHistory[0].timestamp) {
            return LibComitiumStorage.Stake(block.timestamp, 0, block.timestamp, address(0));
        }

        uint256 min = 0;
        uint256 max = stakeHistory.length - 1;

        if (timestamp >= stakeHistory[max].timestamp) {
            return stakeHistory[max];
        }

        // binary search of the value in the array
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (stakeHistory[mid].timestamp <= timestamp) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return stakeHistory[min];
    }

    // votingPower returns the voting power (bonus included) + delegated voting power for a user at the current block
    function votingPower(address user) public view returns (uint256) {
        return votingPowerAtTs(user, block.timestamp);
    }

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp) public view returns (uint256) {
        LibComitiumStorage.Stake memory stake = stakeAtTs(user, timestamp);

        uint256 ownVotingPower;

        // if the user delegated his voting power to another user, then he doesn't have any voting power left
        if (stake.delegatedTo != address(0)) {
            ownVotingPower = 0;
        } else {
            uint256 balance = stake.amount;
            uint256 multiplier = _stakeMultiplier(stake, timestamp);
            ownVotingPower = balance.mul(multiplier).div(BASE_MULTIPLIER);
        }

        uint256 delegatedVotingPower = delegatedPowerAtTs(user, timestamp);

        return ownVotingPower.add(delegatedVotingPower);
    }

    // fdtStaked returns the total raw amount of FDT staked at the current block
    function fdtStaked() public view returns (uint256) {
        return fdtStakedAtTs(block.timestamp);
    }

    // fdtStakedAtTs returns the total raw amount of FDT users have deposited into the contract
    // it does not include any bonus
    function fdtStakedAtTs(uint256 timestamp) public view returns (uint256) {
        return _checkpointsBinarySearch(LibComitiumStorage.comitiumStorage().fdtStakedHistory, timestamp);
    }

    // delegatedPower returns the total voting power that a user received from other users
    function delegatedPower(address user) public view returns (uint256) {
        return delegatedPowerAtTs(user, block.timestamp);
    }

    // delegatedPowerAtTs returns the total voting power that a user received from other users at a point in time
    function delegatedPowerAtTs(address user, uint256 timestamp) public view returns (uint256) {
        return _checkpointsBinarySearch(LibComitiumStorage.comitiumStorage().delegatedPowerHistory[user], timestamp);
    }

    // same as multiplierAtTs but for the current block timestamp
    function multiplierOf(address user) public view returns (uint256) {
        return multiplierAtTs(user, block.timestamp);
    }

    // multiplierAtTs calculates the multiplier at a given timestamp based on the user's stake a the given timestamp
    // it includes the decay mechanism
    function multiplierAtTs(address user, uint256 timestamp) public view returns (uint256) {
        LibComitiumStorage.Stake memory stake = stakeAtTs(user, timestamp);

        return _stakeMultiplier(stake, timestamp);
    }

    // userLockedUntil returns the timestamp until the user's balance is locked
    function userLockedUntil(address user) public view returns (uint256) {
        LibComitiumStorage.Stake memory c = stakeAtTs(user, block.timestamp);

        return c.expiryTimestamp;
    }

    // userDelegatedTo returns the address to which a user delegated their voting power; address(0) if not delegated
    function userDelegatedTo(address user) public view returns (address) {
        LibComitiumStorage.Stake memory c = stakeAtTs(user, block.timestamp);

        return c.delegatedTo;
    }

    // _checkpointsBinarySearch executes a binary search on a list of checkpoints that's sorted chronologically
    // looking for the closest checkpoint that matches the specified timestamp
    function _checkpointsBinarySearch(LibComitiumStorage.Checkpoint[] storage checkpoints, uint256 timestamp) internal view returns (uint256) {
        if (checkpoints.length == 0 || timestamp < checkpoints[0].timestamp) {
            return 0;
        }

        uint256 min = 0;
        uint256 max = checkpoints.length - 1;

        if (timestamp >= checkpoints[max].timestamp) {
            return checkpoints[max].amount;
        }

        // binary search of the value in the array
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].timestamp <= timestamp) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return checkpoints[min].amount;
    }

    // _stakeMultiplier calculates the multiplier for the given stake at the given timestamp
    function _stakeMultiplier(LibComitiumStorage.Stake memory stake, uint256 timestamp) internal view returns (uint256) {
        if (timestamp >= stake.expiryTimestamp) {
            return BASE_MULTIPLIER;
        }

        uint256 diff = stake.expiryTimestamp - timestamp;
        if (diff >= MAX_LOCK) {
            return BASE_MULTIPLIER.mul(2);
        }

        return BASE_MULTIPLIER.add(diff.mul(BASE_MULTIPLIER).div(MAX_LOCK));
    }

    // _updateUserBalance manages an array of checkpoints
    // if there's already a checkpoint for the same timestamp, the amount is updated
    // otherwise, a new checkpoint is inserted
    function _updateUserBalance(LibComitiumStorage.Stake[] storage checkpoints, uint256 amount) internal {
        if (checkpoints.length == 0) {
            checkpoints.push(LibComitiumStorage.Stake(block.timestamp, amount, block.timestamp, address(0)));
        } else {
            LibComitiumStorage.Stake storage old = checkpoints[checkpoints.length - 1];

            if (old.timestamp == block.timestamp) {
                old.amount = amount;
            } else {
                checkpoints.push(LibComitiumStorage.Stake(block.timestamp, amount, old.expiryTimestamp, old.delegatedTo));
            }
        }
    }

    // _updateUserLock updates the expiry timestamp on the user's stake
    // it assumes that if the user already has a balance, which is checked for in the lock function
    // then there must be at least 1 checkpoint
    function _updateUserLock(LibComitiumStorage.Stake[] storage checkpoints, uint256 expiryTimestamp) internal {
        LibComitiumStorage.Stake storage old = checkpoints[checkpoints.length - 1];

        if (old.timestamp < block.timestamp) {
            checkpoints.push(LibComitiumStorage.Stake(block.timestamp, old.amount, expiryTimestamp, old.delegatedTo));
        } else {
            old.expiryTimestamp = expiryTimestamp;
        }
    }

    // _updateUserDelegatedTo updates the delegateTo property on the user's stake
    // it assumes that if the user already has a balance, which is checked for in the delegate function
    // then there must be at least 1 checkpoint
    function _updateUserDelegatedTo(LibComitiumStorage.Stake[] storage checkpoints, address to) internal {
        LibComitiumStorage.Stake storage old = checkpoints[checkpoints.length - 1];

        if (old.timestamp < block.timestamp) {
            checkpoints.push(LibComitiumStorage.Stake(block.timestamp, old.amount, old.expiryTimestamp, to));
        } else {
            old.delegatedTo = to;
        }
    }

    // _updateDelegatedPower updates the power delegated TO the user in the checkpoints history
    function _updateDelegatedPower(LibComitiumStorage.Checkpoint[] storage checkpoints, uint256 amount) internal {
        if (checkpoints.length == 0 || checkpoints[checkpoints.length - 1].timestamp < block.timestamp) {
            checkpoints.push(LibComitiumStorage.Checkpoint(block.timestamp, amount));
        } else {
            LibComitiumStorage.Checkpoint storage old = checkpoints[checkpoints.length - 1];
            old.amount = amount;
        }
    }

    // _updateLockedFdt stores the new `amount` into the FDT locked history
    function _updateLockedFdt(uint256 amount) internal {
        LibComitiumStorage.Storage storage ds = LibComitiumStorage.comitiumStorage();

        if (ds.fdtStakedHistory.length == 0 || ds.fdtStakedHistory[ds.fdtStakedHistory.length - 1].timestamp < block.timestamp) {
            ds.fdtStakedHistory.push(LibComitiumStorage.Checkpoint(block.timestamp, amount));
        } else {
            LibComitiumStorage.Checkpoint storage old = ds.fdtStakedHistory[ds.fdtStakedHistory.length - 1];
            old.amount = amount;
        }
    }
}

