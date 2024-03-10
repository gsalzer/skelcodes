// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.6.10;

import "./_TokenGroups.sol";
import "./__SafeMath.sol";
import "./_Voting.sol";
import "./__Erc20.sol";
import "./_BlockwellQuill.sol";
import "./_Type.sol";

/**
 * Blockwell Prime Token
 */
contract PrimeToken is Erc20, TokenGroups, Type, Voting {
    using SafeMath for uint256;
    using BlockwellQuill for BlockwellQuill.Data;

    /**
     * @dev Stores data for individual token locks used by transferAndLock.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    struct Lock {
        uint256 value;
        uint64 expiration;
        uint32 periodLength;
        uint16 periods;
        bool staking;
    }

    mapping(address => uint256) internal balances;

    mapping(address => uint256) internal stakes;

    mapping(address => mapping(address => uint256)) private allowed;

    mapping(address => Lock[]) locks;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public unlockTime;
    uint256 public transferLockTime;
    string public attorneyEmail;

    uint256 internal totalTokenSupply;

    uint256 public swapNonce;

    bool public suggestionsRestricted = false;
    bool public requireBalanceForVote = false;
    bool public requireBalanceForCreateSuggestion = false;
    uint256 public voteCost;

    uint256 public unstakingDelay = 1 hours;

    BlockwellQuill.Data bwQuill1;

    event SetNewUnlockTime(uint256 unlockTime);
    event MultiTransferPrevented(address indexed from, address indexed to, uint256 value);

    event Locked(
        address indexed owner,
        uint256 value,
        uint64 expiration,
        uint32 periodLength,
        uint16 periodCount
    );
    event Unlocked(address indexed owner, uint256 value, uint16 periodsLeft);

    event SwapToChain(
        string toChain,
        address indexed from,
        address indexed to,
        bytes32 indexed swapId,
        uint256 value
    );
    event SwapFromChain(
        string fromChain,
        address indexed from,
        address indexed to,
        bytes32 indexed swapId,
        uint256 value
    );

    event BwQuillSet(address indexed account, string value);

    event Payment(address indexed from, address indexed to, uint256 value, uint256 order);

    event Stake(address indexed account, uint256 value);
    event Unstake(address indexed account, uint256 value);
    event StakeReward(address indexed account, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) public {
        require(_totalSupply > 0);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalTokenSupply = _totalSupply;

        init(msg.sender);
        bwtype = PRIME;
        bwver = 62;
    }

    function init(address sender) internal virtual {
        _addBwAdmin(sender);
        _addAdmin(sender);

        balances[sender] = totalTokenSupply;
        emit Transfer(address(0), sender, totalTokenSupply);
    }

    /**
     * @dev Allow only when the contract is unlocked, or if the sender is an admin, an attorney, or whitelisted.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    modifier whenUnlocked() {
        expect(
            now > unlockTime || isAdmin(msg.sender) || isAttorney(msg.sender) || isWhitelisted(msg.sender),
            ERROR_TOKEN_LOCKED
        );
        _;
    }

    /**
     * @dev Set a quill 1 value for an account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function setBwQuill(address account, string memory value) public onlyAdminOrAttorney {
        bwQuill1.setString(account, value);
        emit BwQuillSet(account, value);
    }

    /**
     * @dev Get a quill 1 value for any account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getBwQuill(address account) public view returns (string memory) {
        return bwQuill1.getString(account);
    }

    /**
     * @dev Configure how users can vote.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function configureVoting(
        bool restrictSuggestions,
        bool balanceForVote,
        bool balanceForCreateSuggestion,
        uint256 cost,
        bool oneVote
    ) public onlyAdminOrAttorney {
        suggestionsRestricted = restrictSuggestions;
        requireBalanceForVote = balanceForVote;
        requireBalanceForCreateSuggestion = balanceForCreateSuggestion;
        voteCost = cost;
        oneVotePerAccount = oneVote;
    }

    /**
     * @dev Update the email address for this token's assigned attorney.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function setAttorneyEmail(string memory email) public onlyAdminOrAttorney {
        attorneyEmail = email;
    }

    /**
     * @dev Pause the contract, preventing transfers.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function pause() public whenNotPaused {
        bool attorney = isAttorney(msg.sender);
        expect(attorney || isAdmin(msg.sender), ERROR_UNAUTHORIZED);

        _pause(attorney);
    }

    /**
     * @dev Resume the contract.
     *
     * If the contract was originally paused by an attorney, only an attorney can resume.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function unpause() public whenPaused {
        if (!isAttorney(msg.sender)) {
            expect(isAdmin(msg.sender), ERROR_UNAUTHORIZED);
            expect(!pausedByAttorney(), ERROR_ATTORNEY_PAUSE);
        }
        _unpause();
    }

    /**
     * @dev Lock the contract if not already locked until the given time.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function setUnlockTime(uint256 timestamp) public onlyAdminOrAttorney {
        unlockTime = timestamp;
        emit SetNewUnlockTime(unlockTime);
    }

    /**
     * @dev Total number of tokens.
     */
    function totalSupply() public view override returns (uint256) {
        return totalTokenSupply;
    }

    /**
     * @dev Get account balance.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Get allowance for an owner-spender pair.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowed[owner][spender];
    }

    /**
     * @dev Transfer tokens.
     */
    function transfer(address to, uint256 value) public override whenNotPaused whenUnlocked returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Make multiple token transfers with one transaction.
     * @param to Array of addresses to transfer to.
     * @param value Array of amounts to be transferred.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function multiTransfer(address[] calldata to, uint256[] calldata value)
        public
        whenNotPaused
        onlyBundler
        returns (bool)
    {
        expect(to.length > 0, ERROR_EMPTY_ARRAY);
        expect(value.length == to.length, ERROR_LENGTH_MISMATCH);

        for (uint256 i = 0; i < to.length; i++) {
            if (!isFrozen(to[i])) {
                _transfer(msg.sender, to[i], value[i]);
            } else {
                emit MultiTransferPrevented(msg.sender, to[i], value[i]);
            }
        }

        return true;
    }

    /**
     * @dev Approve a spender to transfer the given amount of the sender's tokens.
     */
    function approve(address spender, uint256 value)
        public
        override
        isNotFrozen
        whenNotPaused
        whenUnlocked
        returns (bool)
    {
        expect(spender != address(0), ERROR_INVALID_ADDRESS);

        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from an account the sender has been approved to send from.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override whenNotPaused whenUnlocked returns (bool) {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to multiple others.
     * @param from Address to send from.
     * @param to Array of addresses to transfer to.
     * @param value Array of amounts to be transferred.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function multiTransferFrom(
        address from,
        address[] calldata to,
        uint256[] calldata value
    ) public whenNotPaused onlyBundler returns (bool) {
        expect(to.length > 0, ERROR_EMPTY_ARRAY);
        expect(value.length == to.length, ERROR_LENGTH_MISMATCH);

        for (uint256 i = 0; i < to.length; i++) {
            if (!isFrozen(to[i])) {
                allowed[from][msg.sender] = allowed[from][msg.sender].sub(value[i]);
                _transfer(from, to[i], value[i]);
            } else {
                emit MultiTransferPrevented(from, to[i], value[i]);
            }
        }

        return true;
    }

    /**
     * @dev Increase the amount of tokens a spender can transfer from the sender's account.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        isNotFrozen
        whenNotPaused
        whenUnlocked
        returns (bool)
    {
        expect(spender != address(0), ERROR_INVALID_ADDRESS);

        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens a spender can transfer from the sender's account.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        isNotFrozen
        whenNotPaused
        whenUnlocked
        returns (bool)
    {
        expect(spender != address(0), ERROR_INVALID_ADDRESS);

        allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Lists all the locks for the given account as an array, with [value1, expiration1, value2, expiration2, ...]
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function locksOf(address account) public view returns (uint256[] memory) {
        Lock[] storage userLocks = locks[account];

        uint256[] memory lockArray = new uint256[](userLocks.length * 4);

        for (uint256 i = 0; i < userLocks.length; i++) {
            uint256 pos = 4 * i;
            lockArray[pos] = userLocks[i].value;
            lockArray[pos + 1] = userLocks[i].expiration;
            lockArray[pos + 2] = userLocks[i].periodLength;
            lockArray[pos + 3] = userLocks[i].periods;
        }

        return lockArray;
    }

    /**
     * @dev Unlocks all expired locks.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function unlock() public returns (bool) {
        return _unlock(msg.sender);
    }

    /**
     * @dev Base method for unlocking tokens.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function _unlock(address account) internal returns (bool) {
        Lock[] storage list = locks[account];
        if (list.length == 0) {
            return true;
        }

        for (uint256 i = 0; i < list.length; ) {
            Lock storage lock = list[i];
            if (lock.expiration < block.timestamp) {
                // Less than 2 means it's the last period (1), or periods are not used (0)
                if (lock.periods < 2) {
                    emit Unlocked(account, lock.value, 0);

                    if (i < list.length - 1) {
                        list[i] = list[list.length - 1];
                    }
                    list.pop();
                } else {
                    uint256 value;
                    uint256 diff = block.timestamp.sub(lock.expiration);
                    uint16 periodsPassed = 1 + uint16(diff.div(lock.periodLength));
                    if (periodsPassed >= lock.periods) {
                        periodsPassed = lock.periods;
                        value = lock.value;
                        emit Unlocked(account, value, 0);
                        if (i < list.length - 1) {
                            list[i] = list[list.length - 1];
                        }
                        list.pop();
                    } else {
                        value = lock.value.div(lock.periods) * periodsPassed;

                        lock.periods -= periodsPassed;
                        lock.value = lock.value.sub(value);
                        lock.expiration =
                            lock.expiration +
                            uint32(uint256(lock.periodLength).mul(periodsPassed));
                        emit Unlocked(account, value, lock.periods);
                        i++;
                    }
                }
            } else {
                i++;
            }
        }

        return true;
    }

    /**
     * @dev Gets the unlocked balance of the specified address.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function unlockedBalanceOf(address account) public view returns (uint256) {
        return balances[account].sub(totalLocked(account));
    }

    /**
     * @dev Gets the total usable tokens for an account, including tokens that could be unlocked.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function availableBalanceOf(address account) external view returns (uint256) {
        return balances[account].sub(totalLocked(account)).add(totalUnlockable(account));
    }

    /**
     * @dev Transfers tokens and locks them for lockTime.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function transferAndLock(
        address to,
        uint256 value,
        uint32 lockTime,
        uint32 periodLength,
        uint16 periods
    ) public returns (bool) {
        uint64 expires = uint64(block.timestamp.add(lockTime));
        Lock memory newLock = Lock(value, expires, periodLength, periods, false);
        locks[to].push(newLock);

        transfer(to, value);
        emit Locked(to, value, expires, periodLength, periods);

        return true;
    }

    /**
     * @dev Transfer and lock to multiple accounts with a single transaction.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function multiTransferAndLock(
        address[] calldata to,
        uint256[] calldata value,
        uint32 lockTime,
        uint32 periodLength,
        uint16 periods
    ) public whenNotPaused onlyBundler returns (bool) {
        expect(to.length > 0, ERROR_EMPTY_ARRAY);
        expect(value.length == to.length, ERROR_LENGTH_MISMATCH);

        for (uint256 i = 0; i < to.length; i++) {
            if (!isFrozen(to[i])) {
                transferAndLock(to[i], value[i], lockTime, periodLength, periods);
            } else {
                emit MultiTransferPrevented(msg.sender, to[i], value[i]);
            }
        }

        return true;
    }

    /**
     * @dev Gets the total amount of locked tokens in the given account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function totalLocked(address account) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < locks[account].length; i++) {
            total = total.add(locks[account][i].value);
        }

        return total;
    }

    /**
     * @dev Gets the amount of tokens that can currently be unlocked.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function totalUnlockable(address account) public view returns (uint256) {
        Lock[] storage userLocks = locks[account];
        uint256 total = 0;
        for (uint256 i = 0; i < userLocks.length; i++) {
            Lock storage lock = userLocks[i];
            if (lock.expiration < block.timestamp) {
                if (lock.periods < 2) {
                    total = total.add(lock.value);
                } else {
                    uint256 value;
                    uint256 diff = block.timestamp.sub(lock.expiration);
                    uint16 periodsPassed = 1 + uint16(diff.div(lock.periodLength));
                    if (periodsPassed > lock.periods) {
                        periodsPassed = lock.periods;
                        value = lock.value;
                    } else {
                        value = lock.value.div(lock.periods) * periodsPassed;
                    }

                    total = total.add(value);
                }
            }
        }

        return total;
    }

    /**
     * @dev Withdraw any tokens the contract itself is holding.
     */
    function withdrawTokens() public whenNotPaused {
        expect(isAdmin(msg.sender), ERROR_UNAUTHORIZED);
        _transfer(address(this), msg.sender, balanceOf(address(this)));
    }

    /**
     * @dev Gets an incrementing nonce for generating swap IDs.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getSwapNonce() internal returns (uint256) {
        return ++swapNonce;
    }

    /**
     * @dev Initiates a swap to another chain. Transfers the tokens to this contract and emits an event
     *      indicating the request to swap.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function swapToChain(
        string memory chain,
        address to,
        uint256 value
    ) public whenNotPaused whenUnlocked {
        bytes32 swapId = keccak256(
            abi.encodePacked(getSwapNonce(), msg.sender, to, address(this), chain, value)
        );

        _transfer(msg.sender, address(this), value);
        emit SwapToChain(chain, msg.sender, to, swapId, value);
    }

    /**
     * @dev Completes a swap from another chain, called by a swapper account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function swapFromChain(
        string memory fromChain,
        address from,
        address to,
        bytes32 swapId,
        uint256 value
    ) public whenNotPaused onlySwapper {
        _transfer(address(this), to, value);

        emit SwapFromChain(fromChain, from, to, swapId, value);
    }

    /**
     * @dev Create a new suggestion for voting.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function createSuggestion(string memory text) public {
        if (suggestionsRestricted) {
            expect(isAdmin(msg.sender) || isDelegate(msg.sender), ERROR_UNAUTHORIZED);
        } else if (requireBalanceForCreateSuggestion) {
            expect(balanceOf(msg.sender) > 0, ERROR_INSUFFICIENT_BALANCE);
        }
        _createSuggestion(text);
    }

    /**
     * @dev Vote on a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function vote(uint256 suggestionId, string memory comment) public {
        if (requireBalanceForVote) {
            expect(balanceOf(msg.sender) > 0, ERROR_INSUFFICIENT_BALANCE);
        }

        if (voteCost > 0) {
            _transfer(msg.sender, address(this), voteCost);
        }

        _vote(msg.sender, suggestionId, 1, comment);
    }

    /**
     * @dev Cast multiple votes on a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function multiVote(
        uint256 suggestionId,
        uint256 votes,
        string memory comment
    ) public {
        expect(!oneVotePerAccount, ERROR_DISALLOWED_STATE);

        if (requireBalanceForVote) {
            expect(balanceOf(msg.sender) > 0, ERROR_INSUFFICIENT_BALANCE);
        }

        if (voteCost > 0) {
            _transfer(msg.sender, address(this), voteCost.mul(votes));
        }

        _vote(msg.sender, suggestionId, votes, comment);
    }

    /**
     * @dev Transfer tokens and include an order number for external reference.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function payment(
        address to,
        uint256 value,
        uint256 order
    ) public whenNotPaused whenUnlocked returns (bool) {
        _transfer(msg.sender, to, value);

        emit Payment(msg.sender, to, value, order);
        return true;
    }

    /**
     * @dev Stake tokens, locking them for a minimum of unstakingDelay time.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function stake(uint256 value) public whenNotPaused whenUnlocked returns (bool) {
        expect(!isFrozen(msg.sender), ERROR_FROZEN);

        _unlock(msg.sender);
        expect(value <= unlockedBalanceOf(msg.sender), ERROR_INSUFFICIENT_BALANCE);

        balances[msg.sender] = balances[msg.sender].sub(value);
        stakes[msg.sender] = stakes[msg.sender].add(value);

        emit Transfer(msg.sender, address(0), value);
        emit Stake(msg.sender, value);

        return true;
    }

    /**
     * @dev Get the total staked tokens for an account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function stakeOf(address account) public view returns (uint256) {
        return stakes[account];
    }

    /**
     * @dev Unstake tokens, which will lock them for unstakingDelay time.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function unstake(uint256 value) public whenNotPaused whenUnlocked returns (bool) {
        expect(!isFrozen(msg.sender), ERROR_FROZEN);

        stakes[msg.sender] = stakes[msg.sender].sub(value);
        balances[msg.sender] = balances[msg.sender].add(value);

        if (unstakingDelay > 0) {
            uint64 expires = uint64(block.timestamp.add(unstakingDelay));
            Lock memory newLock = Lock(value, expires, 0, 0, true);
            locks[msg.sender].push(newLock);
            emit Locked(msg.sender, value, expires, 0, 0);
        }

        emit Unstake(msg.sender, value);
        emit Transfer(address(0), msg.sender, value);

        return true;
    }

    /**
     * @dev Configure staking parameters.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function configureStaking(uint256 unstakeDelay) public onlyAdminOrAttorney {
        unstakingDelay = unstakeDelay;
    }

    /**
     * @dev Reward tokens to account stake balances.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function stakeReward(address[] calldata to, uint256[] calldata value)
        public
        whenNotPaused
        returns (bool)
    {
        expect(isAutomator(msg.sender), ERROR_UNAUTHORIZED);
        expect(value.length == to.length, ERROR_LENGTH_MISMATCH);

        for (uint256 i = 0; i < to.length; i++) {
            address account = to[i];
            uint256 val = value[i];
            if (!isFrozen(account)) {
                stakes[account] = stakes[account].add(val);
                balances[msg.sender] = balances[msg.sender].sub(val);

                emit StakeReward(account, val);
                emit Transfer(msg.sender, address(0), val);
            }
        }

        return true;
    }

    /**
     * @dev Base method for transferring tokens.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        expect(to != address(0), ERROR_INVALID_ADDRESS);
        expect(!isFrozen(from), ERROR_FROZEN);
        expect(!isFrozen(to), ERROR_FROZEN);

        _unlock(from);

        expect(value <= unlockedBalanceOf(from), ERROR_INSUFFICIENT_BALANCE);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }
}

