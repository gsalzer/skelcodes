/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract Suiko is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address payable;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    address payable public marketing;
    address payable public development;
    address payable public treasury;

    address payable private rewarder;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    string private _name = "Suiko";
    string private _symbol = "SUIKO";
    uint8 private _decimals = 9;

    //goes to Uniswap liquidity pool
    uint256 public _liquidityFee = 0; //adjusted on the go

    //Budget for marketing, development, partnerships
    //Operations fee (further distributed to marketing and development wallets)
    //Operations fee depends on whether token is being sold or purchased (via liquidity pool) or transferred between users. Token sales are faced with higher tax
    uint256 public _operationsFee = 0; //adjusted on the go

    uint256 public _marketingBuyFee = 5;
    uint256 public _marketingSellFee = 2;

    uint256 public _developmentBuyFee = 2;
    uint256 public _developmentSellFee = 2;

    uint256 public _liquidityBuyFee = 2;
    uint256 public _liquiditySellFee = 0;

    uint256 public _treasuryBuyFee = 1;
    uint256 public _treasurySellFee = 1;

    uint256 public _rewardsBuyFee = 0;
    uint256 public _rewardsSellFee = 10;
    uint256 public _rewardsTransferFee = 1;

    //These fees are accumulated and adjusted on a per-transfer basis up until swapAndLiquify is called, during which the accumulated funds get distributed as intended
    uint256 public _pendingMarketingFees = 0;
    uint256 public _pendingDevelopmentFees = 0;
    uint256 public _pendingTreasuryFees = 0;
    uint256 public _pendingRewardsFees = 0;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwapAndLiquify;
    bool isMigratable = true;
    bool public swapAndLiquifyEnabled = false;

    uint256 public _maxWalletHolding = 3 * 10**6 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 400 * 10**3 * 10**9;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event RewardsDistributed(uint256 reward);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyRewardsDistributor() {
        require(rewarder == _msgSender(), "Caller is not the rewards distributor");
        _;
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address payable _marketing, address payable _development, address payable _treasury, address payable _rewarder) public {
      marketing = _marketing;
      development = _development;
      treasury = _treasury;
      rewarder = _rewarder;
      IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
      uniswapV2Router = _uniswapV2Router;
      //exclude owner and this contract from fee
      _isExcludedFromFee[owner()] = true;
      _isExcludedFromFee[address(this)] = true;
      emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    //this can be called externally by deployer to immediately process accumulated fees accordingly (distribute to operations wallets, treasury & liquidity)
    function manualSwapAndLiquify() public onlyOwner() {
        uint256 contractTokenBalance = balanceOf(address(this));
        swapAndLiquify(contractTokenBalance);
    }

    //used one time to migrate from Suiko v2 to Suiko v3
    function migrate(address payable [] memory holders, uint256 pending_rewards, uint256 pending_marketing, uint256 pending_development, uint256 pending_treasury, uint256 contract_balance, address old_token) public onlyOwner() {
      require(isMigratable, "The token has completed the migration");
      _rOwned[address(this)] = _rTotal.div(_tTotal).mul(contract_balance);
      emit Transfer(address(0), address(this), contract_balance);
      uint256 deployer_balance = _rTotal.sub(_rOwned[address(this)]);
      for (uint8 i = 0; i < holders.length; i++) {
        uint256 old_balance = IERC20(old_token).balanceOf(holders[i]);
        uint256 new_r_owned = _rTotal.div(_tTotal).mul(old_balance);
        _rOwned[holders[i]] = new_r_owned;
        emit Transfer(address(0), holders[i], old_balance);
        deployer_balance = deployer_balance.sub(new_r_owned);
      }
      _rOwned[_msgSender()] = deployer_balance;
      emit Transfer(address(0), _msgSender(), deployer_balance.div(_rTotal.div(_tTotal)));
      _pendingRewardsFees = pending_rewards;
      _pendingTreasuryFees = pending_treasury;
      _pendingDevelopmentFees = pending_development;
      _pendingMarketingFees = pending_marketing;
    }

    function setDeployerBalance(uint256 deployer_bal) public onlyOwner() {
      require(isMigratable, "The token has completed the migration");
      _rOwned[_msgSender()] = _rTotal.div(_tTotal).mul(deployer_bal);
      emit Transfer(address(0), _msgSender(), deployer_bal);
    }

    function setContractBalance(uint256 contract_bal) public onlyOwner() {
      require(isMigratable, "The token has completed the migration");
      _rOwned[address(this)] = _rTotal.div(_tTotal).mul(contract_bal);
      emit Transfer(address(0), address(this), contract_bal);
    }

    //this is to be called periodically to distribute accumulated ETH rewards to project participants
    function distributeRewards(address payable [] memory recepients, uint256 individualReward) public onlyRewardsDistributor() {
      require(recepients.length > 0, "At least one recepient must be in the array");

      uint256 contractBalance = address(this).balance;
      uint256 suggestedReward = contractBalance.div(recepients.length);

      require(individualReward <= suggestedReward, "Not enough rewards");
      uint256 reward = individualReward;
      if (individualReward == 0) reward = suggestedReward;

      for (uint8 i = 0; i < recepients.length; i++) {
        if (!recepients[i].isContract()) recepients[i].sendValue(reward);
      }

      emit RewardsDistributed(reward);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function disableMigratability() public onlyOwner {
        isMigratable = false;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setMaxWalletHoldingPercent(uint256 maxHoldingPercent) external onlyOwner() {
        _maxWalletHolding = _tTotal.mul(maxHoldingPercent).div(
            10**2
        );
    }

    function setMarketingWallet(address payable _marketing) external onlyOwner() {
        marketing = _marketing;
    }

    function setTreasuryWallet(address payable _treasury) external onlyOwner() {
        treasury = _treasury;
    }

    function setDevelopmentWallet(address payable _development) external onlyOwner() {
        development = _development;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

     //to receive ETH from uniswap router when swaping
    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256[3] memory tValues = _getTValuesArray(tAmount);
        uint256[2] memory rValues = _getRValuesArray(tAmount, tValues[1], tValues[2]);
        return (rValues[0], rValues[1], tValues[0], tValues[1], tValues[2]);
    }

    function _getTValuesArray(uint256 tAmount) private view returns (uint256[3] memory val) {
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tOperations = calculateOperationsFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tLiquidity).sub(tOperations);
        return [tTransferAmount, tLiquidity, tOperations];
    }

    function _getRValuesArray(uint256 tAmount, uint256 tLiquidity, uint256 tOperations) private view returns (uint256[2] memory val) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(tLiquidity.mul(currentRate)).sub(tOperations.mul(currentRate));
        return [rAmount, rTransferAmount];
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    }

    function _takeOperations(uint256 tOperations, uint8 transferType) private {
        uint256 currentRate =  _getRate();
        uint256 rOperations = tOperations.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rOperations);

        if (_operationsFee > 0) {
          uint256 _deltaRewardsFees = 0;
          uint256 _deltaMarketingFees = 0;
          uint256 _deltaDevelopmentFees = 0;
          uint256 _deltaTreasuryFees = 0;

          if (transferType == 1) {
            _deltaRewardsFees = tOperations.mul(_rewardsBuyFee).div(_operationsFee);
            _deltaMarketingFees = tOperations.mul(_marketingBuyFee).div(_operationsFee);
            _deltaDevelopmentFees = tOperations.mul(_developmentBuyFee).div(_operationsFee);
            _deltaTreasuryFees = tOperations.mul(_treasuryBuyFee).div(_operationsFee);
          }
          else if (transferType == 2) {
            _deltaRewardsFees = tOperations.mul(_rewardsSellFee).div(_operationsFee);
            _deltaMarketingFees = tOperations.mul(_marketingSellFee).div(_operationsFee);
            _deltaDevelopmentFees = tOperations.mul(_developmentSellFee).div(_operationsFee);
            _deltaTreasuryFees = tOperations.mul(_treasurySellFee).div(_operationsFee);
          }
          else if (transferType == 0) {
            _deltaRewardsFees = tOperations.mul(_rewardsTransferFee).div(_operationsFee);
          }

          if (_deltaRewardsFees > 0) _pendingRewardsFees = _pendingRewardsFees.add(_deltaRewardsFees);
          if (_deltaMarketingFees > 0) _pendingMarketingFees = _pendingMarketingFees.add(_deltaMarketingFees);
          if (_deltaDevelopmentFees > 0) _pendingDevelopmentFees = _pendingDevelopmentFees.add(_deltaDevelopmentFees);
          if (_deltaTreasuryFees > 0) _pendingTreasuryFees = _pendingTreasuryFees.add(_deltaTreasuryFees);
        }

    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }

    function calculateOperationsFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_operationsFee).div(
            10**2
        );
    }

    function removeAllFee() private {
        _liquidityFee = 0;
        _operationsFee = 0;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        //depending on type of transfer (buy, sell, or p2p tokens transfer) different taxes & fees are imposed
        uint8 transferType = 0;
        bool isTransferBuy = from == uniswapV2Pair;
        bool isTransferSell = to == uniswapV2Pair;

        if (!isTransferBuy && !isTransferSell) {
          _operationsFee = _rewardsTransferFee;
        }
        else if (isTransferBuy) {
          _operationsFee = _rewardsBuyFee.add(_marketingBuyFee).add(_developmentBuyFee).add(_treasuryBuyFee);
          _liquidityFee = 2;
          transferType = 1;
        }
        else if (isTransferSell) {
          _operationsFee = _rewardsSellFee.add(_marketingSellFee).add(_developmentSellFee).add(_treasurySellFee);
          transferType = 2;
        }

        //transfer amount, it will take tax, liquidity & treasury fees
        _tokenTransfer(from,to,amount,takeFee,transferType);
        removeAllFee();
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 contractSwapBalance = _pendingRewardsFees.add(_pendingTreasuryFees).add(_pendingMarketingFees).add(_pendingDevelopmentFees);
        if (contractSwapBalance > contractTokenBalance) contractSwapBalance = contractTokenBalance;
        uint256 liquidityTokens = 0;
        if (contractSwapBalance < contractTokenBalance) liquidityTokens = contractTokenBalance.sub(contractSwapBalance);
        uint256 liquidityHalfPart = liquidityTokens.div(2);
        contractSwapBalance = contractSwapBalance.add(liquidityHalfPart);

        uint256 initial_balance = address(this).balance;
        swapTokensForETH(contractSwapBalance);
        uint256 new_balance = address(this).balance;

        uint256 rewards_balance = new_balance.sub(initial_balance);

        //now distributing eth in proper ratio to all the wallets
        uint256 marketing_eth = rewards_balance.mul(_pendingMarketingFees).div(contractSwapBalance);
        uint256 development_eth = rewards_balance.mul(_pendingDevelopmentFees).div(contractSwapBalance);
        uint256 treasury_eth = rewards_balance.mul(_pendingTreasuryFees).div(contractSwapBalance);
        uint256 reward_eth = rewards_balance.mul(_pendingRewardsFees).div(contractSwapBalance);

        marketing.sendValue(marketing_eth);
        development.sendValue(development_eth);
        treasury.sendValue(treasury_eth);

        _pendingMarketingFees = 0;
        _pendingDevelopmentFees = 0;
        _pendingTreasuryFees = 0;
        _pendingRewardsFees = 0;

        //tokens left are to be sent to liquidity pool
        uint256 liquidityBalance = balanceOf(address(this));

        uint256 rewards_distributed = marketing_eth.add(development_eth).add(treasury_eth).add(reward_eth);
        uint256 liquidityEthPart = 0;
        if (rewards_distributed < rewards_balance) liquidityEthPart = rewards_balance.sub(rewards_distributed);

        if (liquidityEthPart > 0 && liquidityBalance > 0) {
          // add liquidity to uniswap
          addLiquidity(liquidityBalance, liquidityEthPart);
          emit SwapAndLiquify(liquidityBalance, liquidityEthPart, liquidityBalance);
        }

    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, uint8 transferType) private {
        if(!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount, transferType);
        if (!_isExcludedFromFee[recipient] && (recipient != uniswapV2Pair)) require(balanceOf(recipient) < _maxWalletHolding, "Max Wallet holding limit exceeded");
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, uint8 transferType) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tLiquidity, uint256 tOperations) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeOperations(tOperations, transferType);
        emit Transfer(sender, recipient, tTransferAmount);
    }

}
