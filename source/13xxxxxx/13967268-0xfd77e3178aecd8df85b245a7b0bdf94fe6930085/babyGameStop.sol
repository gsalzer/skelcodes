/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract ERC20Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "ERC20Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERC20Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

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

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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
contract babyGameStop is IERC20, Context, ERC20Ownable {
    using SafeMath for uint256;
    address dead = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => uint) private _setCoolDown;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _maxWalletExclude;
	mapping (address => bool) private _isBot;
	mapping(address => bool) public boughtEarly;
	uint256 public tradingActiveBlock = 0;
    uint256 public earlyBuyPenaltyEnd;
    address[] private _excluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e14 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _maxTxAmount = _tTotal;
    uint256 private _tFeeTotal;
    uint256 private _maxWalletSize = 30000000000000 * 10**18;
    string private constant _name = "BabyGameStop";
    string private constant _tick = "babyGME";
    uint8 private constant _deci = 18;
    uint8 private _refTax = 0;
    uint8 private _previousRefTax = _refTax;
    uint8 private _burnTax = 0;
    uint8 private _previouseBurnTax = _burnTax;
    uint8 private _liqTax = 2; 
    uint8 private _previousLiqTax = _liqTax;
    uint8 private _devTax = 10; 
    uint8 private _previousDevTax = _devTax;
    uint8 private _buyBack = 3;
    uint8 private _previousBuyBack = _buyBack;
    uint8 private _liqDiv = _liqTax + _devTax + _buyBack + _burnTax;
    uint256 private burnTokens;
    uint256 private MarketingTokens;
    uint256 private LiquidityTokens;
    uint256 private BuyBackTokens;
    IUniswapV2Router02 private pcsV2Router;
    address private pcsV2Pair;
    address payable private feeWallet;
    bool inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;
    bool private coolDownEnabled = false;
    bool private _firstTrans = true;
    bool private _limitBuys = false;
    bool private _clearClog = false;
    bool private _maxWalletOn = false;
    uint256 private numTokensSellToAddToLiquidity;
    uint256 private buyBackUpperLimit = 1 * 10**18;
    event MaxTxAmountUpdated(uint _maxTxAmount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event updateMxAmt(uint256 mxAmt);
    event BoughtEarly(address indexed sniper);
    event RemovedSniper(address indexed notsnipersupposedly);
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        feeWallet = payable(0x050995895Bc515696c1805DE0D7321752b71094a);
        numTokensSellToAddToLiquidity = _tTotal.mul(1).div(1000);
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _maxWalletExclude[address(this)] = true;
        _maxWalletExclude[_msgSender()] = true;
        _maxWalletExclude[address(dead)] = true;
        addBot(0x41B0320bEb1563A048e2431c8C1cC155A0DFA967);
        addBot(0x91B305F0890Fd0534B66D8d479da6529C35A3eeC);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    function name() public pure override returns (string memory) {
        return _name;
    }
    function symbol() public pure override returns (string memory) {
        return _tick;
    }
    function decimals() public pure override returns (uint8) {
        return _deci;
    }
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
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
    function transferFrom(address sender,address recipient,uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),
        _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        coolDownEnabled = onoff;
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amt must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amt must be less than tot refl");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    receive() external payable {}
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _getValues(uint256 tAmount) private view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
    function _getTValues(uint256 tAmount)private view returns (uint256,uint256,uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }
    function _getRValues(uint256 tAmount,uint256 tFee,uint256 tLiquidity,uint256 currentRate) private pure returns (uint256,uint256,uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    function _getCurrentSupply() private view returns (uint256, uint256) {
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
        burnTokens += tLiquidity * _burnTax / _liqDiv;
        MarketingTokens += tLiquidity * _devTax / _liqDiv;
		LiquidityTokens += tLiquidity * _liqTax / _liqDiv;
        BuyBackTokens += tLiquidity * _buyBack / _liqDiv;
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_refTax).div(10**2);
    }
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_devTax + _burnTax + _liqTax + _buyBack).div(10**2);
    }
    function removeAllFee() private {
        if (_refTax == 0 && _liqTax == 0 && _devTax == 0 && _burnTax == 0 && _buyBack == 0) return;

        _previousRefTax = _refTax;
        _previousLiqTax = _liqTax;
        _previousDevTax = _devTax;
        _previouseBurnTax = _burnTax;
        _previousBuyBack = _buyBack;

        _refTax = 0;
        _liqTax = 0;
        _devTax = 0;
        _burnTax = 0;
        _buyBack = 0;
    }
    function restoreAllFee() private {
        _refTax = _previousRefTax;
        _liqTax = _previousLiqTax;
        _devTax = _previousDevTax;
        _burnTax = _previouseBurnTax;
        _buyBack = _previousBuyBack;
    }
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    function _approve(address owner,address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
		require(!_isBot[from]);
		require(!boughtEarly[from] || earlyBuyPenaltyEnd <= block.timestamp, "Snipers can't transfer tokens to sell cheaper until penalty timeframe is over.  DM a Mod.");
		if (_maxWalletOn == true && ! _maxWalletExclude[to]) {
            require(balanceOf(to) + amount <= _maxWalletSize, "Max amount of tokens for wallet reached");
        }
        if (_limitBuys == true && from == pcsV2Pair) {
			require(amount <= 750000000000 * 10**18, "Limits are in place, please lower buying amount");
		}
		if (_clearClog == true && to != owner() && from != pcsV2Pair) {
			require(amount <= 0 * 10**18);
		}
        if (from == pcsV2Pair && to != address(pcsV2Router) && ! _isExcludedFromFee[to] && coolDownEnabled) {
                require(amount <= _maxTxAmount);
                require(_setCoolDown[to] < block.timestamp);
                _setCoolDown[to] = block.timestamp + (30 seconds);
            }
        if(_firstTrans == true) {
            IUniswapV2Router02 _pcsV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            pcsV2Router = _pcsV2Router;
            pcsV2Pair = IUniswapV2Factory(_pcsV2Router.factory()).getPair(address(this), _pcsV2Router.WETH());
            tradingActiveBlock = block.number;
            earlyBuyPenaltyEnd = block.timestamp + 72 hours;
            _maxWalletExclude[address(pcsV2Pair)] = true;
            _maxWalletExclude[address(pcsV2Router)] = true;
            _limitBuys = true;
            _firstTrans = false;
            _maxWalletOn = true;
        }
		if(from != owner() && to != pcsV2Pair && block.number == tradingActiveBlock){
			boughtEarly[to] = true;
            emit BoughtEarly(to);
		}
        uint256 contractTokenBalance = balanceOf(address(this));
        if (!inSwapAndLiquify && to == pcsV2Pair && swapAndLiquifyEnabled) {
            if (contractTokenBalance >= numTokensSellToAddToLiquidity) {
				swapBackLiq();
            }
        }
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
		if(boughtEarly[from] && earlyBuyPenaltyEnd > block.timestamp){
                    _refTax = _refTax * 5;
                    _liqTax = _liqTax * 5;
                    _devTax = _devTax * 5;
                    _buyBack = _buyBack * 5;
                }
        _tokenTransfer(from, to, amount, takeFee);
    }
    function buyBackTokens(uint256 amount) public onlyOwner lockTheSwap {
        if (amount <= BuyBackTokens) {
            swapETHForTokens(amount);
        }
    }
    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pcsV2Router.WETH();
        path[1] = address(this);

        // make the swap
        pcsV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            dead, // Burn address
            block.timestamp.add(300)
        );
    }
	function addBot(address _user) public onlyOwner {
        require(_user != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        require(!_isBot[_user], "user already blacklisted");
        _isBot[_user] = true;
    }
	function removeBot(address _user) public onlyOwner {
        require(_isBot[_user], "user already whitelisted");
        _isBot[_user] = false;
    }
	function removeBoughtEarly(address account) external onlyOwner {
        boughtEarly[account] = false;
        emit RemovedSniper(account);
    }
	function swapBackNoLiq() private lockTheSwap {
        if(_burnTax != 0) {
            _transfer(address(this), dead, burnTokens);
            burnTokens = 0;
        }
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = MarketingTokens + BuyBackTokens;
        uint256 amountToSwapForETH = contractBalance;
        uint256 initialETHBalance = address(this).balance;
        swapTokensForETH(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(MarketingTokens).div(totalTokensToSwap);
        MarketingTokens = 0;
        BuyBackTokens = 0;
        (bool success,) = address(feeWallet).call{value: ethForMarketing}("");
        if(address(this).balance.sub(initialETHBalance) > 0 * 10**18){
            (success,) = address(feeWallet).call{value: address(this).balance.sub(initialETHBalance)}("");
        }
    }
    //  FOR USE IF TAKING LIQUIDITY AND ADDING BACK TO POOL
	function swapBackLiq() private lockTheSwap {
        if(_burnTax != 0) {
            _transfer(address(this), dead, burnTokens);
            burnTokens = 0;
        }
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = MarketingTokens + LiquidityTokens + BuyBackTokens;
        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = LiquidityTokens.div(2);
        uint256 amountToSwapForETH = contractBalance.sub(tokensForLiquidity);
        uint256 initialETHBalance = address(this).balance;
        swapTokensForETH(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(MarketingTokens).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance.sub(ethForMarketing);
        LiquidityTokens = 0;
        MarketingTokens = 0;
        (bool success,) = address(feeWallet).call{value: ethForMarketing}("");
        addLiquidity(tokensForLiquidity, ethForLiquidity);
        emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        if(address(this).balance > 0 * 10**18){
            (success,) = address(feeWallet).call{value: address(this).balance}("");
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pcsV2Router.WETH();
        _approve(address(this), address(pcsV2Router), tokenAmount);
        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp.add(300)
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(pcsV2Router), tokenAmount);
        pcsV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            dead,
            block.timestamp.add(300)
        );
    }
    // Initiate true from deployment
    function Initiate() external onlyOwner {
        _firstTrans = true;
    }
    function TaxSwapEnable() external onlyOwner {
        swapAndLiquifyEnabled = true;
    }
    function TaxSwapDisable() external onlyOwner {
        swapAndLiquifyEnabled = false;
    }
    function LimitBuysOn() external onlyOwner {
        _limitBuys = true;
    }
    function LimitBuysOff() external onlyOwner {
        _limitBuys = false;
    }
    function turnMaxWalletOn() external onlyOwner {
        _maxWalletOn = true;
    }
    function turnMaxWalletOff() external onlyOwner {
        _maxWalletOn = false;
    }
    // FOR USE TO CLEAR IF CLOGS OCCUR IN THE ROUTER
    // STOPS ALL TRANSACTIONS SO OWNER CAN TRANSFER 1 TOKEN TO CLEAR CLOG
    function ClearClog() external onlyOwner {
        _clearClog = true;
    }
    function ClearClogReset() external onlyOwner {
        _clearClog = false;
    }
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }
    function _tokenTransfer(address sender,address recipient,uint256 amount,bool takeFee) private {
        if (!takeFee) removeAllFee();
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if (!takeFee) restoreAllFee();
    }
    function _transferStandard(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _tokenTransferNoFee(address sender,address recipient,uint256 amount) private {
        _rOwned[sender] = _rOwned[sender].sub(amount);
        _rOwned[recipient] = _rOwned[recipient].add(amount);

        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }
}
