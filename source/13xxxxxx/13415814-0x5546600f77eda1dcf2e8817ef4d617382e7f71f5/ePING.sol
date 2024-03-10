/**	
 * 
$$$$$$$\        $$$$$$\       $$\   $$\        $$$$$$\  
$$  __$$\       \_$$  _|      $$$\  $$ |      $$  __$$\ 
$$ |  $$ |        $$ |        $$$$\ $$ |      $$ /  \__|
$$$$$$$  |        $$ |        $$ $$\$$ |      $$ |$$$$\ 
$$  ____/         $$ |        $$ \$$$$ |      $$ |\_$$ |
$$ |              $$ |        $$ |\$$$ |      $$ |  $$ |
$$ |            $$$$$$\       $$ | \$$ |      \$$$$$$  |
\__|            \______|      \__|  \__|       \______/ 
                                                        
*                                                   
*/  
/* PING
*
* Taxes structure:
*
* 3% taxes for Liquidity
* 2% reflected to HODLERS
* 3% operation/dev/marketing wallet
* 2% research wallet
*
* Total supply: 4 billion tokens.

https://www.sonarplatform.io/

World's first crypto metatracker - AI-driven data aggregation platform

*
*/

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
     function mint(address from, uint256 value) external;
     function burn(address from, uint256 value) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.8.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        address addr = msg.sender;
        address payable Sender = payable(addr);
        return Sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

//pragma solidity >=0.6.2;


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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

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

// File: contracts/PING.sol

pragma solidity ^0.8.0;
// SPDX-License-Identifier: None

/* PING
*
* Taxes structure:
*
* 3% taxes for Liquidity
* 2% reflected to HODLERS
* 3% operation/dev/marketing wallet
* 2% research wallet
*
*
*/

contract ePING is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping(address => bool) public adminAddresses;
    address[] private _excluded;
    bool public isWalletTransferFeeEnabled = false;
    bool public isContractTransferFeeEnabled = true;

    string private constant _name = "ePING";
    string private constant _symbol = "ePING";
    uint8 private constant _decimals = 9;

    uint256 private constant MAX = 16 * 10**36 * 10**_decimals;
    uint256 private  _tTotal = 1 * 10**0 * 10**_decimals;
    
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tRfiTotal;
    uint256 public numOfHODLers;
    uint256 private _tDevelopmentTotal;
    uint256 private _tResearchTotal;
    
    //@dev enable optimisation to pack this in 32b
    struct feeRatesStruct {
      uint8 rfi;
      uint8 liquidity;
      uint8 research;
      uint8 dev;
    }

    feeRatesStruct public feeRates = feeRatesStruct(
     {rfi: 2,
      liquidity: 3,
      research: 2,
      dev: 3}); //32 bytes - perfect, as it should be

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tLiquidity;
      uint256 tResearch;
      uint256 tDev;
    }

    address public researchWallet;
    address public devWallet;
    mapping (address => bool) public isPresaleWallet;//exclude presaleWallet from max transaction limit, so that public can claim tokens.
    
    IUniswapV2Router02 public  PancakeSwapV2Router;
    address public  pancakeswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxTxAmount = 4 * 10**9  * 10**_decimals;  
    uint256 public numTokensSellToAddToLiquidity = 4 * 10**6 * 10**_decimals;   //0.1%

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiquidity);
    event BalanceWithdrawn(address withdrawer, uint256 amount);
    event LiquidityAdded(uint256 tokenAmount, uint256 bnbAmount);
    event MaxTxAmountChanged(uint256 oldValue, uint256 newValue);
    event SwapAndLiquifyStatus(string status);
    event WalletsChanged();
    event FeesChanged();
    event tokensBurned(uint256 amount, string message);
    event Mint(uint256 amount, address mintAddress);
    event Burn(uint256 amount, address burnAddress);


    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _PancakeSwapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        pancakeswapV2Pair = IUniswapV2Factory(_PancakeSwapV2Router.factory()).createPair(address(this), _PancakeSwapV2Router.WETH()); //only utility is to have the pair at hand, on bscscan...
        PancakeSwapV2Router = _PancakeSwapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    function toggleWalletTransferTax() external onlyOwner {
        isWalletTransferFeeEnabled = !isWalletTransferFeeEnabled;
    }

    function toggleContractTransferTax() external onlyOwner {
        isContractTransferFeeEnabled = !isContractTransferFeeEnabled;
    }

    //std ERC20:
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    //override ERC20:
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient,amount, isWalletTransferFeeEnabled);
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
       if (sender.isContract()) {
            _transfer(sender, recipient, amount, isContractTransferFeeEnabled);
        } else {
            _transfer(sender, recipient, amount, isWalletTransferFeeEnabled);
        }
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tRfiTotal;
    }

  

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromRFI(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInRFI(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFeeAndRfi(address account) public onlyOwner {
        excludeFromFee(account);
        excludeFromRFI(account);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    /* @dev passing an array or just an uint256 would have been more efficient/elegant, I know
    */
    function setRfiRatesPercents(uint8 _rfi, uint8 _lp, uint8 _research, uint8 _dev) public onlyOwner {
      feeRates.rfi = _rfi;
      feeRates.liquidity = _lp;
      feeRates.research = _research;
      feeRates.dev = _dev;
      emit FeesChanged();
    }

    function setWallets(address _research, address _dev) public onlyOwner {
      researchWallet = _research;
      devWallet = _dev;
      _isExcludedFromFee[_research] = true;
      _isExcludedFromFee[_dev] = true;
      emit WalletsChanged();
    }

    function setPresaleWallet(address _presaleWallet) public onlyOwner {
      _isExcludedFromFee[_presaleWallet] = true;
      isPresaleWallet[_presaleWallet]=true;
    }

   function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        uint256 _previoiusAmount = _maxTxAmount;
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(100);
        emit MaxTxAmountChanged(_previoiusAmount, _maxTxAmount);
    }
    
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    //@dev swapLiq is triggered only when the contract's balance is above this threshold
    function setThreshholdForLP(uint256 threshold) external onlyOwner {
      numTokensSellToAddToLiquidity = threshold * 10**_decimals;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //  @dev receive BNB from pancakeswapV2Router when swapping
    receive() external payable {}

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal = _rTotal.sub(rRfi);
        _tRfiTotal = _tRfiTotal.add(tRfi);
    }

    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi) = _getRValues(to_return, tAmount, takeFee, _getRate());

        return to_return;

    }

    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
            s.tTransferAmount = tAmount;
            return s;
        }

        s.tRfi = tAmount.mul(feeRates.rfi).div(100);
        s.tLiquidity = tAmount.mul(feeRates.liquidity).div(100);
        s.tResearch = tAmount.mul(feeRates.research).div(100);
        s.tDev = tAmount.mul(feeRates.dev).div(100);

        s.tTransferAmount = tAmount.sub(s.tRfi).sub(s.tLiquidity).sub(s.tResearch).sub(s.tDev);

        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi) {

        rAmount = tAmount.mul(currentRate); //wondering how rfi works ? This is the trick

        if(!takeFee) {
          return(rAmount, rAmount, 0);
        }

        rRfi = s.tRfi.mul(currentRate);
        uint256 rLiquidity = s.tLiquidity.mul(currentRate);
        uint256 rResearch = s.tResearch.mul(currentRate);
        uint256 rDev = s.tDev.mul(currentRate);

        rTransferAmount = rAmount.sub(rRfi).sub(rLiquidity).sub(rResearch).sub(rDev);

        return (rAmount, rTransferAmount, rRfi);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    

    function _transfer(address from, address to, uint256 amount , bool takeFee) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"Insuf balance, check balance at SafeSale.finance if you have token lock");
        //Exclude owner and presale wallets from maxTxAmount.
        if((from != owner() && to != owner()) && ( !isPresaleWallet[from] &&  !isPresaleWallet[to]))  
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (overMinTokenBalance && !inSwapAndLiquify && from != pancakeswapV2Pair && swapAndLiquifyEnabled) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        bool shouldTakeFeeForTransfer = takeFee &&
            !(_isExcludedFromFee[from] || _isExcludedFromFee[to]);

        _tokenTransfer(from, to, amount, shouldTakeFeeForTransfer);
    }


    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {
        if (_rOwned[recipient] == 0) {numOfHODLers++;}
        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender] && !_isExcluded[recipient]) {  //from excluded
                _tOwned[sender] = _tOwned[sender].sub(tAmount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient].add(s.tTransferAmount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) { //both excluded
                _tOwned[sender] = _tOwned[sender].sub(tAmount);
                _tOwned[recipient] = _tOwned[recipient].add(s.tTransferAmount);
        }

        //common to all transfers and == transfer std :
        _rOwned[sender] = _rOwned[sender].sub(s.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(s.rTransferAmount);

        _takeLiquidity(s.tLiquidity);
        _reflectRfi(s.rRfi, s.tRfi);
        reflectDevandResearchFee(s.tDev,s.tResearch);

        emit Transfer(sender, recipient, s.tTransferAmount);
    }


    function reflectDevandResearchFee(uint256 tDev, uint256 tResearch) private {
        uint256 currentRate =  _getRate();
        uint256 rDevelopent =  tDev.mul(currentRate);
        uint256 rResearch =  tResearch.mul(currentRate);
        _tDevelopmentTotal = _tDevelopmentTotal.add(tDev);
        _rOwned[devWallet] = _rOwned[devWallet].add(rDevelopent);
        _tResearchTotal = _tResearchTotal.add(tResearch);
        _rOwned[researchWallet] = _rOwned[researchWallet].add(rResearch);
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        if(swapTokensForBNB(half)) { //enough liquidity ? If not, no swapLiq
          uint256 newBalance = address(this).balance.sub(initialBalance);
          addLiquidity(otherHalf, newBalance);
          emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }

    // @dev This is used by the swapAndLiquify function to swap to BNB
    // allowance optimisation, only when needed - max allowance since spender=uniswap
    function swapTokensForBNB(uint256 tokenAmount) private returns (bool status){

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PancakeSwapV2Router.WETH();

        if(allowance(address(this), address(PancakeSwapV2Router)) < tokenAmount) {
          _approve(address(this), address(PancakeSwapV2Router), ~uint256(0));
        }

        try PancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,0,path,address(this),block.timestamp) {
          emit SwapAndLiquifyStatus("Success");
          return true;
        }
        catch {
          emit SwapAndLiquifyStatus("Failed");
          return false;
        }

    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        PancakeSwapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
        emit LiquidityAdded(tokenAmount, bnbAmount);
    }

    function totalDevelopmentFee() public view returns (uint256) {
        return _tDevelopmentTotal;
    }
    
    function totalResearchFee() public view returns (uint256) {
        return _tResearchTotal;
    }
    
    function adminConfig(address adminAddress , bool isAdmin) external onlyOwner {
        adminAddresses[adminAddress] = isAdmin;
    }

    modifier onlyAdmin() {
        require(adminAddresses[_msgSender()], "Caller is not an admin.");
        _;
    }

    function _mint(address recipient, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_tTotal + amount <= 4 * 10**9 * 10**_decimals, "Total supply cannot exceed 4B");
        
        uint256 _rTransferAmount = (amount.mul(_rTotal)).div(_tTotal);
        
        _tTotal = _tTotal.add(amount);
        _rTotal = _rTotal.add(_rTransferAmount);

        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(amount);
        }

        _rOwned[recipient] = _rOwned[recipient].add(_rTransferAmount);

        emit Transfer(address(0), recipient, amount);
    }

    function _burn(address senderAddress, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(senderAddress), "Insufficient balance");
        require(_tTotal - amount >= 0, "Total supply cannot be below 0");

        uint256 _rTransferAmount = (amount.mul(_rTotal)).div(_tTotal);
        
        _tTotal = _tTotal.sub(amount);
        _rTotal = _rTotal.sub(_rTransferAmount);

        if (_isExcluded[senderAddress]) {
            _tOwned[senderAddress] = _tOwned[senderAddress].sub(amount);
        }

        _rOwned[senderAddress] = _rOwned[senderAddress].sub(_rTransferAmount);

        emit Transfer(senderAddress, address(0), amount);
    }

    function mint(address recipient, uint256 value)
        external
        override
        onlyAdmin
    {
        _mint(recipient, value);
        emit Mint(value, recipient);
    }

    function burn(address fromAddress, uint256 value) external override onlyAdmin {
        _burn(fromAddress, value);
        emit Burn(value, fromAddress);
    }
}
