/*
Shikage SHKG

Telegram: https://t.me/shikageofficial
Website: https://shikage.space/
Facebook: https://www.facebook.com/Shikage.ETH/
Instagram: https://www.instagram.com/shikage_token/
Twitter: https://twitter.com/ShikageEth
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.11;


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * C U ON THE MOON
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

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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
}

interface IAntiSnipe {
  function setTokenOwner(address owner) external;

  function onPreTransferCheck(
    address from,
    address to,
    uint256 amount
  ) external returns (bool checked);
}

contract Shikage is IERC20, Ownable {
    using Address for address;
    
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Shikage";
    string constant _symbol = "SHKG";
    uint8 constant _decimals = 9;

    uint256 constant _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = (_totalSupply * 1) / 200;
    uint256 public _maxWalletSize = (_totalSupply * 1) / 100;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) lastBuy;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 liquidityFee = 20;
    uint256 marketingFee = 50;
    uint256 devFee = 30;
    uint256 totalFee = 100;
    uint256 sellBias = 0;
    uint256 sellPercent = 250;
    uint256 sellPeriod = 72 hours;
    uint256 feeDenominator = 1000;

    address public constant liquidityReceiver = 0x51FE1EDbC149556eF2867115E58616428aA2C19A;
    address payable public constant marketingReceiver = payable(0x51FE1EDbC149556eF2867115E58616428aA2C19A);
    address payable public constant devReceiver = payable(0x592Ab8ED942c7Eb84cB27616f1Dcb57669DFD901);

    uint256 targetLiquidity = 40;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public immutable router;
    
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping (address => bool) liquidityPools;
    mapping (address => bool) liquidityProviders;

    address public immutable pair;

    uint256 public launchedAt;
    uint256 public launchedTime;
    bool public pauseDisabled = false;
    
    IAntiSnipe public antisnipe;
    bool public protectionEnabled = true;
    bool public protectionDisabled = false;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 400;
    uint256 public swapMinimum = _totalSupply / 10000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        liquidityPools[pair] = true;
        _allowances[owner()][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;
        
        isFeeExempt[owner()] = true;
        liquidityProviders[msg.sender] = true;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[routerAddress] = true;

        _balances[owner()] = _totalSupply;
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function setProtection(bool _protect) external onlyOwner {
        if (_protect)
            require(!protectionDisabled);
        protectionEnabled = _protect;
    }
    
    function setProtection(address _protection, bool _call) external onlyOwner {
        if (_protection != address(antisnipe)){
            require(!protectionDisabled);
            antisnipe = IAntiSnipe(_protection);
        }
        if (_call)
            antisnipe.setTokenOwner(msg.sender);
    }
    
    function disableProtection() external onlyOwner {
        protectionDisabled = true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        require(amount > 0, "Zero amount transferred");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkTxLimit(sender, amount);
        
        if (!liquidityPools[recipient] && recipient != DEAD) {
            if (!isTxLimitExempt[recipient]) checkWalletLimit(recipient, amount);
        }

        if(!launched()){ require(liquidityProviders[sender] || liquidityProviders[recipient], "Contract not launched yet."); }

        _balances[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender) && shouldTakeFee(recipient) ? takeFee(sender, recipient, amount) : amount;
        
        if(shouldSwapBack(recipient)){ if (amount > 0) swapBack(amount); }
        
        _balances[recipient] += amountReceived;
            
        if(launched() && protectionEnabled)
            antisnipe.onPreTransferCheck(sender, recipient, amount);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function checkWalletLimit(address recipient, uint256 amount) internal view {
        uint256 walletLimit = _maxWalletSize;
        require(_balances[recipient] + amount <= walletLimit, "Transfer amount exceeds the bag size.");
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
    
    function setLiquidityProvider(address _provider) external onlyOwner {
        isFeeExempt[_provider] = true;
        liquidityProviders[_provider] = true;
        isTxLimitExempt[_provider] = true;
    }

    function getTotalFee(bool selling, bool inHighPeriod) public view returns (uint256) {
        if(launchedAt + 1 > block.number){ return feeDenominator - 1; }
        if (selling) return inHighPeriod ? (totalFee * sellPercent) / 100 : totalFee + sellBias;
        return inHighPeriod ? (totalFee * sellPercent) / 100 : totalFee - sellBias;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * getTotalFee(liquidityPools[recipient], !liquidityPools[sender] && lastBuy[sender] + sellPeriod > block.timestamp)) / feeDenominator;
        
        if (liquidityPools[sender] && lastBuy[recipient] == 0)
            lastBuy[recipient] = block.timestamp;

        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return !liquidityPools[msg.sender]
        && !isFeeExempt[msg.sender]
        && !inSwap
        && swapEnabled
        && liquidityPools[recipient]
        && _balances[address(this)] >= swapMinimum &&
        totalFee > 0;
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 amountToSwap = amount < swapThreshold ? amount : swapThreshold;
        if (_balances[address(this)] < amountToSwap) amountToSwap = _balances[address(this)];
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = ((amountToSwap * dynamicLiquidityFee) / totalFee) / 2;
        amountToSwap -= amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 contractBalance = address(this).balance;
        uint256 totalETHFee = totalFee - dynamicLiquidityFee / 2;

        uint256 amountLiquidity = (contractBalance * dynamicLiquidityFee) / totalETHFee / 2;
        uint256 amountMarketing = (contractBalance * marketingFee) / totalETHFee;
        uint256 amountDev = contractBalance - (amountLiquidity + amountMarketing);

        if(amountToLiquify > 0) {
            router.addLiquidityETH{value: amountLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountLiquidity, amountToLiquify);
        }
        
        if (amountMarketing > 0)
            marketingReceiver.transfer(amountMarketing);
            
        if (amountDev > 0)
            devReceiver.transfer(amountDev);

    }

    function setSellPeriod(uint256 _sellPercentIncrease, uint256 _period) external onlyOwner {
        require((totalFee * _sellPercentIncrease) / 100 <= 400, "Sell tax too high");
        require(_period <= 7 days, "Sell period too long");
        sellPercent = _sellPercentIncrease;
        sellPeriod = _period;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() external onlyOwner {
        require (launchedAt == 0);
        launchedAt = block.number;
        launchedTime = block.timestamp;
    }

    function setTxLimit(uint256 numerator, uint256 divisor) external onlyOwner {
        require(numerator > 0 && divisor > 0 && (numerator * 1000) / divisor >= 5);
        _maxTxAmount = (_totalSupply * numerator) / divisor;
    }
    
    function setMaxWallet(uint256 numerator, uint256 divisor) external onlyOwner() {
        require(divisor > 0 && divisor <= 10000);
        _maxWalletSize = (_totalSupply * numerator) / divisor;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _devFee, uint256 _sellBias, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        devFee = _devFee;
        sellBias = _sellBias;
        totalFee = _liquidityFee + _marketingFee + _devFee;
        feeDenominator = _feeDenominator;
        require(totalFee <= feeDenominator / 4);
        require(sellBias <= totalFee);
    }

    function setSwapBackSettings(bool _enabled, uint256 _denominator, uint256 _denominatorMin) external onlyOwner {
        require(_denominator > 0 && _denominatorMin > 0);
        swapEnabled = _enabled;
        swapMinimum = _totalSupply / _denominatorMin;
        swapThreshold = _totalSupply / _denominator;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return (accuracy * balanceOf(pair)) / getCirculatingSupply();
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function addLiquidityPool(address _pool, bool _enabled) external onlyOwner {
        liquidityPools[_pool] = _enabled;
    }

	function airdrop(address[] calldata _addresses, uint256[] calldata _amount) external onlyOwner
    {
        require(_addresses.length == _amount.length);
        bool previousSwap = swapEnabled;
        swapEnabled = false;
        //This function may run out of gas intentionally to prevent partial airdrops
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(!liquidityPools[_addresses[i]]);
            _transferFrom(msg.sender, _addresses[i], _amount[i] * (10 ** _decimals));
        }
        swapEnabled = previousSwap;
    }

    event AutoLiquify(uint256 amount, uint256 amountToken);
    //C U ON THE MOON
}
