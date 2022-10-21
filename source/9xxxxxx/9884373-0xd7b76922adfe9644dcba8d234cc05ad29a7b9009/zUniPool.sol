
// File: @openzeppelin/contracts/math/Math.sol

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/IRewardDistributionRecipient.sol

pragma solidity ^0.5.0;


contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint256 reward, uint256 duration) external;

    modifier onlyRewardDistribution() {
        require(
            _msgSender() == rewardDistribution,
            "Caller is not reward distribution"
        );
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}

// File: contracts/Unipool.sol

pragma solidity ^0.5.0;






contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public uni = IERC20(0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        uni.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        uni.safeTransfer(msg.sender, amount);
    }
}

contract Unipool is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public snx = IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward, uint256 duration);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored
                .add(lastTimeRewardApplicable().sub(lastUpdateTime))
                .mul(rewardRate)
                .mul(1e18)
                .div(totalSupply());
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function stake(uint256 amount) public updateReward(msg.sender) {
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() public {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            snx.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Duration is the time diff from (now  - when snx rewards will be mintable again) to handle slippage in minting
    function notifyRewardAmount(uint256 reward, uint256 duration)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            periodFinish = block.timestamp.add(duration);
            rewardRate = reward.div(duration);
            emit RewardAdded(reward, duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            periodFinish = block.timestamp.add(duration);
            rewardRate = reward.add(leftover).div(duration);
            emit RewardAdded(reward, duration);
        }
    }
}

// File: contracts/iUniswapExchangeContract.sol

// Solidity Interface
pragma solidity ^0.5.0;

interface UniswapExchangeInterface {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) external payable returns (uint256);
    function removeLiquidity(
        uint256 amount,
        uint256 min_eth,
        uint256 min_tokens,
        uint256 deadline
    ) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold)
        external
        view
        returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought)
        external
        view
        returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought)
        external
        view
        returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)
        external
        payable
        returns (uint256 tokens_bought);
    function ethToTokenTransferInput(
        uint256 min_tokens,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline)
        external
        payable
        returns (uint256 eth_sold);
    function ethToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256 eth_bought);
    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external returns (uint256 eth_bought);
    function tokenToEthSwapOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline
    ) external returns (uint256 tokens_sold);
    function tokenToEthTransferOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline,
        address recipient
    ) external returns (uint256 tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address token_addr
    ) external returns (uint256 tokens_bought);
    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_bought);
    function tokenToTokenSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address token_addr
    ) external returns (uint256 tokens_sold);
    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256 tokens_bought);
    function tokenToExchangeTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256 tokens_bought);
    function tokenToExchangeSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256 tokens_sold);
    function tokenToExchangeTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256 tokens_sold);

}

// File: contracts/zUniPool.sol

pragma solidity ^0.5.0;



contract zUniPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // --- ERC20 Data ---
    string public constant name = "zUNIT";
    string public constant symbol = "zUNIT";
    string public constant version = "1";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    /**
     - Need to check impact of Uniswap V2,  will we need to deploy a v2 or new version of DZSLT
     due to changes in sETH_LP_TokenAddress and potentially a new version of SNXUniswapTokenAddress?
    */
    address public constant UnipoolAddress = 0x48D7f315feDcaD332F68aafa017c7C158BC54760;
    IERC20 public constant sETHTokenAddress = IERC20(
        0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb
    );
    IERC20 public constant sETH_LP_TokenAddress = IERC20(
        0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244
    );
    IERC20 public constant SNXTokenAddress = IERC20(
        0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F
    );
    IERC20 public constant SNXUniSwapTokenAddress = IERC20(
        0x3958B4eC427F8fa24eB60F42821760e88d485f7F
    );

    uint256 public totalLPTokensStaked;

    bool public stopped;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public allowedAddress;

    // events
    event LPTokensStaked(address indexed staker, uint256 qtyStaked);
    event LPTokensWithdrawn(address indexed leaver, uint256 qtyWithdrawn);
    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
 
    // testing events
    event internall(string, uint256);

    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    modifier allowedToStake {
        require(allowedAddress[msg.sender], "you are not allowed to stake through this contract");
        _;
    }

    function allowTheAddress(address _permittedAccount) public onlyOwner {
        allowedAddress[_permittedAccount] = true;
    }

    function removeTheAddress(address _removalAccount) public onlyOwner {
        require(balanceOf[_removalAccount] == 0, "this address still holds some tokens and cannot be removed");
        allowedAddress[_removalAccount] = false;
    }

    constructor() public {
        approve_Addresses();
        stopped = false;
    }

    function approve_Addresses() public {
        sETH_LP_TokenAddress.approve(UnipoolAddress, ((2**256) - 1));
        SNXTokenAddress.approve(
            address(SNXUniSwapTokenAddress),
            ((2**256) - 1)
        );
        sETHTokenAddress.approve(address(sETH_LP_TokenAddress), ((2**256) - 1));
    }

    // reader functions

    function howMuchHasThisContractStaked()
        public
        view
        returns (uint256 LPTokens)
    {
        return Unipool(UnipoolAddress).balanceOf(address(this));
    }

    function howMuchHasThisContractEarned()
        public
        view
        returns (uint256 SNXEarned)
    {
        return Unipool(UnipoolAddress).earned(address(this));
    }

    /**
     * @dev Returs the amount of LP redemeemable / to be staked for a given quantity of zUNI
     */
    function howMuchIszUNIWorth(uint256 _zUNIinWEI)
        external
        view
        returns (uint256)
    {
        if (totalSupply > 0) {
            if (
                Unipool(UnipoolAddress).earned(address(this)) > 0.000005 ether
            ) {
                uint256 eth4SNX = min_eth(
                    (Unipool(UnipoolAddress).earned(address(this))),
                    address(SNXUniSwapTokenAddress)
                );
                uint256 maxTokens = getMaxTokens(
                    address(sETH_LP_TokenAddress),
                    sETHTokenAddress,
                    ((eth4SNX).mul(4985)).div(10000)
                );
                uint256 notinalLP = totalLPTokensStaked.add(maxTokens);
                return (((_zUNIinWEI).mul(notinalLP)).div(totalSupply));
            } else {
                return (
                    ((_zUNIinWEI).mul(totalLPTokensStaked)).div(totalSupply)
                );
            }
        } else {
            return (1);
        }

    }

    // action functions
    function stakeMyShare(uint256 _LPTokenUints) public allowedToStake stopInEmergency returns (uint256) {
        // transfer to this address
        sETH_LP_TokenAddress.transferFrom(
            msg.sender,
            address(this),
            _LPTokenUints
        );

        uint256 tokens = issueTokens(msg.sender, _LPTokenUints);
        emit internall("tokens", tokens);

        Unipool(UnipoolAddress).stake(_LPTokenUints);

        totalLPTokensStaked = totalLPTokensStaked.add(_LPTokenUints);
        return (tokens);
    }

    function issueTokens(address toWhom, uint256 howMuchLPStaked)
        internal
        returns (uint256 tokensIssued)
    {
        (uint256 totalLPs, uint256 totalzUNIs) = getDetails(true);
        uint256 tokens2bIssued = (howMuchLPStaked.mul(totalzUNIs)).div(
            totalLPs
        );
        emit internall("howMuchLPStaked", howMuchLPStaked);
        emit internall("tokens2bIssued", tokens2bIssued);
        mint(toWhom, tokens2bIssued);
        return tokens2bIssued;
    }

    function getDetails(bool enter)
        internal
        returns (uint256 totalLPs, uint256 totalzUNIs)
    {
        if (totalSupply == 0) {
            emit internall("entering phase 1", 0);
            return (1, 1);
        } else {
            emit internall("entering phase 2", 1);
            return (reBalance(enter), totalSupply);
        }
    }

    function reBalance(bool enter) public returns (uint256 LPTokenWealth) {
        /* @dev: it does not make economical sense to claim reward if the SNX 
        / earned is less than 0.000005; considering the price of SNX at the time 
        / of writing this contract
        */

        if (howMuchHasThisContractEarned() > 0.000005 ether) {
            emit internall(
                "Earnings more than the threshold",
                howMuchHasThisContractEarned()
            );
            Unipool(UnipoolAddress).getReward();
            uint256 SNXInHandHoldings = SNXTokenAddress.balanceOf(
                address(this)
            );
            emit internall("Claiming Reward", SNXInHandHoldings);
            uint256 LPJustReceived = convertSNXtoLP(SNXInHandHoldings);
            emit internall("LPJustReceived", LPJustReceived);
            if (enter) {
                Unipool(UnipoolAddress).stake(LPJustReceived);
                totalLPTokensStaked = totalLPTokensStaked.add(LPJustReceived);
                emit internall("totalLPTokensStaked", totalLPTokensStaked);
                return (totalLPTokensStaked);
            } else {
                return (totalLPTokensStaked.add(LPJustReceived));
            }

        } else {
            return (totalLPTokensStaked);
        }
    }

    function convertSNXtoLP(uint256 SNXQty)
        internal
        returns (uint256 LPReceived)
    {
        uint256 SNX2BcETH = SafeMath.mul(SNXQty, 4985).div(10000);
        uint256 SNX2BcSETH = SafeMath.sub(SNXQty, SNX2BcETH);

        uint256 ETHfromSNX = UniswapExchangeInterface(
            address(SNXUniSwapTokenAddress)
        )
            .tokenToEthSwapInput(
            SNX2BcETH,
            (
                (
                    min_eth(SNX2BcETH, address(SNXUniSwapTokenAddress))
                        .mul(995)
                        .div(1000)
                )
            ),
            now.add(300)
        );

        // converting a portion of the SNX to sETH for the purpose of adding liquidity
        UniswapExchangeInterface(address(SNXUniSwapTokenAddress))
            .tokenToTokenSwapInput(
            SNX2BcSETH,
            min_tokens(
                (min_eth(SNX2BcSETH, address(SNXUniSwapTokenAddress)).mul(995))
                    .div(1000),
                address(sETH_LP_TokenAddress)
            ),
            (
                min_eth(SNX2BcSETH, address(SNXUniSwapTokenAddress))
                    .mul(995)
                    .div(1000)
            ),
            now.add(300),
            address(sETHTokenAddress)
        );

        // adding liquidity
        uint256 LPU = UniswapExchangeInterface(address(sETH_LP_TokenAddress))
            .addLiquidity
            .value(ETHfromSNX)(
            1,
            getMaxTokens(
                address(sETH_LP_TokenAddress),
                sETHTokenAddress,
                ETHfromSNX
            ),
            now.add(300)
        );

        // converting the balance sETH to SNX

        UniswapExchangeInterface(address(sETH_LP_TokenAddress))
            .tokenToTokenSwapInput(
            (sETHTokenAddress.balanceOf(address(this))),
            min_tokens(
                (
                    min_eth(
                        (sETHTokenAddress.balanceOf(address(this))),
                        address(sETH_LP_TokenAddress)
                    )
                        .mul(995)
                        .div(1000)
                ),
                address(SNXUniSwapTokenAddress)
            ),
            (
                min_eth(
                    (sETHTokenAddress.balanceOf(address(this))),
                    address(sETH_LP_TokenAddress)
                )
                    .mul(995)
                    .div(1000)
            ),
            now.add(300),
            address(SNXTokenAddress)
        );

        return LPU;
    }

    function getMaxTokens(address uniExchAdd, IERC20 ERC20Add, uint256 value)
        internal
        view
        returns (uint256)
    {
        uint256 contractBalance = address(uniExchAdd).balance;
        uint256 eth_reserve = SafeMath.sub(contractBalance, value);
        uint256 token_reserve = ERC20Add.balanceOf(uniExchAdd);
        uint256 token_amount = SafeMath.div(
            SafeMath.mul(value, token_reserve),
            eth_reserve
        ) +
            1;
        return token_amount;
    }

    function min_eth(uint256 tokenQTY, address uniExchAdd)
        internal
        view
        returns (uint256)
    {
        return
            UniswapExchangeInterface(uniExchAdd).getTokenToEthInputPrice(
                tokenQTY
            );
    }

    function min_tokens(uint256 ethAmt, address uniExchAdd)
        internal
        view
        returns (uint256)
    {
        return
            UniswapExchangeInterface(uniExchAdd).getEthToTokenInputPrice(
                ethAmt
            );
    }

    function getMyStakeOut(uint256 _tokenQTY)
        public stopInEmergency
        returns (uint256 LPTokensReleased)
    {
        require(balanceOf[msg.sender] >= _tokenQTY, "Withdrawing qty invalid");
        (uint256 totalLPs, uint256 totalzUNIs) = getDetails(false);
        uint256 LPs2bRedemeed = (_tokenQTY.mul(totalLPs)).div(totalzUNIs);
        uint256 LPsInHand = sETH_LP_TokenAddress.balanceOf(address(this));
        if (LPs2bRedemeed > LPsInHand) {
            uint256 LPsShortOf = LPs2bRedemeed.sub(LPsInHand);
            Unipool(UnipoolAddress).withdraw(LPsShortOf);
            sETH_LP_TokenAddress.transfer(msg.sender, LPs2bRedemeed);
            totalLPTokensStaked = totalLPTokensStaked.sub(LPs2bRedemeed);
        } else {
            sETH_LP_TokenAddress.transfer(msg.sender, LPs2bRedemeed);
            uint256 leftOverLPs = sETH_LP_TokenAddress.balanceOf(address(this));
            if (leftOverLPs > 0) {
                Unipool(UnipoolAddress).stake(leftOverLPs);
                totalLPTokensStaked = totalLPTokensStaked.add(leftOverLPs);
            }
        }
        burn(msg.sender, _tokenQTY);
        return (LPs2bRedemeed);
    }

    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        // _beforeTokenTransfer(address(0), account, amount);
        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        // _beforeTokenTransfer(account, address(0), amount);
        balanceOf[account] = balanceOf[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            allowance[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount)
        internal
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        // _beforeTokenTransfer(sender, recipient, amount);
        balanceOf[sender] = balanceOf[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function() external payable {
        emit internall("got cash", msg.value);
    }

    // governance functions

    function getRewardOut() public onlyOwner returns (uint totalSNXReward) {
        require(stopped, "first pause the contract");
        Unipool(UnipoolAddress).getReward();
        emit internall("Owner Took out reward", SNXTokenAddress.balanceOf(
                address(this)
            ));
        inCaseTokengetsStuck(SNXTokenAddress);
        return (SNXTokenAddress.balanceOf(address(this)));
    }

    function withdrawAllStaked() public onlyOwner returns (uint totalStakedUintsWithdrawn) {
        uint stakedUints = Unipool(UnipoolAddress).balanceOf(address(this));
        Unipool(UnipoolAddress).withdraw(stakedUints);
        inCaseTokengetsStuck(sETH_LP_TokenAddress);
        emit internall("total staked uints taken out", stakedUints);
        return (stakedUints);
    }

    // - to kill the contract
    function destruct() public onlyOwner {
        withdrawAllStaked();
        getRewardOut();
        address owner_ = owner();
        selfdestruct(address(uint160(owner_)));
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        address owner_ = owner();
        address(uint160(owner_)).transfer(address(this).balance);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        address owner_ = owner();
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner_, qty);
    }

}

