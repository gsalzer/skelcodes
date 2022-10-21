pragma solidity 0.5.17;


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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */

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

interface ICurveDeposit {
    function add_liquidity(uint[4] calldata uamounts, uint min_mint_amount) external;
    function remove_liquidity_imbalance(uint[4] calldata uamounts, uint max_burn_amount) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_uamount, bool donate_dust) external;
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns(uint);
}

interface ICurve {
    function add_liquidity(uint[4] calldata uamounts, uint min_mint_amount) external;
    function remove_liquidity_imbalance(uint[4] calldata uamounts, uint max_burn_amount) external;
    function remove_liquidity(uint amount, uint[4] calldata min_amounts) external;
    function calc_token_amount(uint[4] calldata inAmounts, bool deposit) external view returns(uint);
    function balances(int128 i) external view returns(uint);
    function get_virtual_price() external view returns(uint);

    // for tests
    function mock_add_to_balance(uint[4] calldata amounts) external;
}

interface IUtil {
    function get_D(uint[4] calldata uamounts) external pure returns(uint);
}

interface ICore {
    function mint(uint dusdAmount, address account) external returns(uint usd);
    function redeem(uint dusdAmount, address account) external returns(uint usd);
    function rewardDistributionCheckpoint(bool shouldDistribute) external returns(uint periodIncome);

    function lastPeriodIncome() external view returns(uint _totalAssets, uint _periodIncome, uint _adminFee);
    function usdToDusd(uint usd) external view returns(uint);
    function dusdToUsd(uint _dusd, bool fee) external view returns(uint usd);
}

contract IPeak {
    function updateFeed(uint[] calldata _prices) external;
    function portfolioValue() public view returns(uint);
}

contract Initializable {
    bool initialized = false;

    modifier notInitialized() {
        require(!initialized, "already initialized");
        initialized = true;
        _;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private _gap;
}

contract Ownable {
    bytes32 constant OWNER_SLOT = keccak256("proxy.owner");

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address _owner) {
        bytes32 position = OWNER_SLOT;
        assembly {
            _owner := sload(position)
        }
    }

    modifier onlyOwner() {
        require(isOwner(), "NOT_OWNER");
        _;
    }

    function isOwner() public view returns (bool) {
        return owner() == msg.sender;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner(), newOwner);
        bytes32 position = OWNER_SLOT;
        assembly {
            sstore(position, newOwner)
        }
    }
}

interface IGauge {
    function deposit(uint) external;
    function balanceOf(address) external view returns (uint);
    function withdraw(uint, bool) external;
    function claim_rewards() external;
}

interface IMintr {
    function mint(address) external;
}

contract CurveSusdPeak is Ownable, Initializable, IPeak {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using Math for uint;

    uint constant MAX = uint(-1);
    uint constant N_COINS = 4;
    string constant ERR_SLIPPAGE = "They see you slippin";

    uint[N_COINS] ZEROES = [uint(0),uint(0),uint(0),uint(0)];
    address[N_COINS] public underlyingCoins;
    uint[N_COINS] public oraclePrices;

    ICurveDeposit curveDeposit; // deposit contract
    ICurve curve; // swap contract
    IERC20 curveToken; // LP token contract
    IUtil util;
    IGauge gauge;
    IMintr mintr;
    ICore core;

    function initialize(
        ICurveDeposit _curveDeposit,
        ICurve _curve,
        IERC20 _curveToken,
        ICore _core,
        IUtil _util,
        IGauge _gauge,
        IMintr _mintr,
        address[N_COINS] memory _underlyingCoins
    )   public
        notInitialized
    {
        curveDeposit = _curveDeposit;
        curve = _curve;
        curveToken = _curveToken;
        core = _core;
        util = _util;
        gauge = _gauge;
        mintr = _mintr;
        underlyingCoins = _underlyingCoins;
        replenishApprovals(MAX);
    }

    /**
    * @dev Mint DUSD
    * @param inAmounts Exact inAmounts in the same order as required by the curve pool
    * @param minDusdAmount Minimum DUSD to mint, used for capping slippage
    */
    function mint(uint[N_COINS] calldata inAmounts, uint minDusdAmount)
        external
        returns (uint dusdAmount)
    {
        address[N_COINS] memory coins = underlyingCoins;
        for (uint i = 0; i < N_COINS; i++) {
            if (inAmounts[i] > 0) {
                IERC20(coins[i]).safeTransferFrom(msg.sender, address(this), inAmounts[i]);
            }
        }

        uint _old = portfolioValue();
        curve.add_liquidity(inAmounts, 0);
        uint _new = portfolioValue();

        dusdAmount = core.mint(_new.sub(_old), msg.sender);
        require(dusdAmount >= minDusdAmount, ERR_SLIPPAGE);
        stake();
    }

    /**
    * @notice Mint DUSD with Curve LP tokens
    * @param inAmount Exact amount of Curve LP tokens
    * @param minDusdAmount Minimum DUSD to mint, used for capping slippage
    */
    function mintWithScrv(uint inAmount, uint minDusdAmount)
        external
        returns (uint dusdAmount)
    {
        dusdAmount = core.mint(sCrvToUsd(inAmount), msg.sender);
        require(dusdAmount >= minDusdAmount, ERR_SLIPPAGE);
        curveToken.safeTransferFrom(msg.sender, address(this), inAmount);
        stake();
    }

    /**
    * @dev Redeem DUSD
    * @param dusdAmount Exact dusdAmount to burn
    * @param minAmounts Min expected amounts to cap slippage
    */
    function redeem(uint dusdAmount, uint[N_COINS] calldata minAmounts)
        external
    {
        uint sCrv = sCrvBalance()
            .min(usdToScrv(core.redeem(dusdAmount, msg.sender)));
        _withdraw(sCrv);
        curve.remove_liquidity(sCrv, ZEROES);
        address[N_COINS] memory coins = underlyingCoins;
        IERC20 coin;
        uint toTransfer;
        for (uint i = 0; i < N_COINS; i++) {
            coin = IERC20(coins[i]);
            toTransfer = coin.balanceOf(address(this));
            require(toTransfer >= minAmounts[i], ERR_SLIPPAGE);
            coin.safeTransfer(msg.sender, toTransfer);
        }
    }

    function redeemInSingleCoin(uint dusdAmount, uint i, uint minOut)
        external
    {
        uint sCrv = sCrvBalance()
            .min(usdToScrv(core.redeem(dusdAmount, msg.sender)));
        _withdraw(sCrv);
        curveDeposit.remove_liquidity_one_coin(sCrv, int128(i), minOut, false);
        IERC20 coin = IERC20(underlyingCoins[i]);
        uint toTransfer = coin.balanceOf(address(this));
        require(toTransfer >= minOut, ERR_SLIPPAGE);
        coin.safeTransfer(msg.sender, toTransfer);
    }

    function redeemInScrv(uint dusdAmount, uint minOut)
        external
    {
        uint sCrv = sCrvBalance()
            .min(usdToScrv(core.redeem(dusdAmount, msg.sender)));
        require(sCrv >= minOut, ERR_SLIPPAGE);
        _withdraw(sCrv);
        curveToken.safeTransfer(msg.sender, sCrv);
    }

    /**
    * @notice Stake in sCrv Gauge
    */
    function stake() public {
        gauge.deposit(curveToken.balanceOf(address(this)));
    }

    function updateFeed(uint[] calldata _prices) external {
        require(msg.sender == address(core), "ERR_NOT_AUTH");
        require(_prices.length == N_COINS, "ERR_INVALID_UPDATE");
        for (uint i = 0; i < N_COINS; i++) {
            oraclePrices[i] = _prices[i];
        }
    }

    // This is risky (Bancor Hack Scenario).
    // Think about if we need strict token approvals during the actions at the cost of higher gas.
    function replenishApprovals(uint value) public {
        curveToken.safeIncreaseAllowance(address(curveDeposit), value);
        curveToken.safeIncreaseAllowance(address(gauge), value);
        for (uint i = 0; i < N_COINS; i++) {
            IERC20(underlyingCoins[i]).safeIncreaseAllowance(address(curve), value);
        }
    }

    function getRewards(address[] calldata tokens, address destination) external onlyOwner {
        harvest();
        for (uint i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            require(
                address(token) != address(curveToken),
                "Admin can't withdraw curve lp tokens"
            );
            token.safeTransfer(destination, token.balanceOf(address(this)));
        }
    }

    function harvest() public {
        mintr.mint(address(gauge));
        gauge.claim_rewards();
    }

    /* ##### View Functions ##### */

    function calcMint(uint[N_COINS] memory inAmounts)
        public view
        returns (uint dusdAmount)
    {
        uint usd = sCrvToUsd(curve.calc_token_amount(inAmounts, true /* deposit */));
        return core.usdToDusd(usd);
    }

    function calcMintWithScrv(uint inAmount)
        public view
        returns (uint dusdAmount)
    {
        return core.usdToDusd(sCrvToUsd(inAmount));
    }

    function calcRedeem(uint dusdAmount)
        public view
        returns(uint[N_COINS] memory amounts)
    {
        uint usd = core.dusdToUsd(dusdAmount, true);
        uint exchangeRate = sCrvToUsd(1e18);
        uint sCrv = usd.mul(1e18).div(exchangeRate);
        uint totalSupply = curveToken.totalSupply();
        for(uint i = 0; i < N_COINS; i++) {
            amounts[i] = curve.balances(int128(i)).mul(sCrv).div(totalSupply);
        }
    }

    function calcRedeemWithScrv(uint dusdAmount)
        public view
        returns(uint amount)
    {
        uint usd = core.dusdToUsd(dusdAmount, true);
        uint exchangeRate = sCrvToUsd(1e18);
        amount = usd.mul(1e18).div(exchangeRate);
    }

    function calcRedeemInSingleCoin(uint dusdAmount, uint i)
        public view
        returns(uint amount)
    {
        uint sCrv = usdToScrv(core.dusdToUsd(dusdAmount, true));
        amount = curveDeposit.calc_withdraw_one_coin(sCrv, int128(i));
    }

    function portfolioValue() public view returns(uint) {
        return sCrvToUsd(sCrvBalance());
    }

    function sCrvBalance() public view returns(uint) {
        return curveToken.balanceOf(address(this))
            .add(gauge.balanceOf(address(this)));
    }

    function usdToScrv(uint usd) public view returns(uint sCrv) {
        uint exchangeRate = sCrvToUsd(1e18);
        if (exchangeRate > 0) {
            return usd.mul(1e18).div(exchangeRate);
        }
    }

    function sCrvToUsd(uint sCrvBal) public view returns(uint) {
        uint sCrvTotalSupply = curveToken.totalSupply();
        if (sCrvTotalSupply == 0 || sCrvBal == 0) {
            return 0;
        }
        uint[N_COINS] memory balances;
        uint[N_COINS] memory prices = oraclePrices;
        for (uint i = 0; i < N_COINS; i++) {
            balances[i] = curve.balances(int128(i)).mul(prices[i]);
            if (i == 0 || i == 3) {
                balances[i] = balances[i].div(1e18);
            } else {
                balances[i] = balances[i].div(1e6);
            }
        }
        // https://github.com/curvefi/curve-contract/blob/pool_susd_plain/vyper/stableswap.vy#L149
        return util.get_D(balances).mul(sCrvBal).div(sCrvTotalSupply);
    }

    function deps() public view returns(
        address _curveDeposit,
        address _curve,
        address _curveToken,
        address _util,
        address _gauge,
        address _mintr,
        address _core
    ) {
        return(
            address(curveDeposit),
            address(curve),
            address(curveToken),
            address(util),
            address(gauge),
            address(mintr),
            address(core)
        );
    }

    /* ##### Internal Functions ##### */

    function _withdraw(uint sCrv) internal {
        uint bal = curveToken.balanceOf(address(this));
        if (sCrv > bal) {
            gauge.withdraw(sCrv.sub(bal), false);
        }
    }
}
