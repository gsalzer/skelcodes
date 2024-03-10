/**

Gencoin Capital is a community-driven token that aims to bring generational wealth 
for it's holders. Powered by a unique investment treasury and a turbo-charged tokenomic 
system, Gencoin is strategically designed to incentivize holders with token buybacks, 
holder giveaways and charity events.

Website: https://gencoincapital.finance
Telegram: https://t.me/gencoincapital
Twitter: https://twitter.com/gencoincapital

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

contract GencoinCapital is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address payable private devWallet = payable (0xc446883641359C7b192EB7006f27dA97B8F454ac); // Main tax wallet
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isSniper;

    uint256 public deadBlocks = 5;    
    uint256 public launchedAtBlock = 0;
    uint256 public launchedAtTime = 0;
    
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isMaxWalletExempt;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    struct StaticMaxTax {
        uint256 maxLiquidity;
        uint256 maxReflection;
        uint256 maxTreasury;
        uint256 maxMarketing;
        uint256 maxTeamfee;
    }
   
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    uint8 private _decimals = 9;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1e17 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Gencoin Capital";
    string private _symbol = "$GENCAP";
    
    uint256 public _maxWalletToken = _tTotal.div(2000).mul(10); //1% of available tokens (500T)

    bool public maxEthTradesEnabled = true;
    uint256 public maxEthSell_launch = 1 * 10**18; //Max sell is 1 ETH for 24 hours.
    uint256 public maxEthSell = 5 * 10**18; //Regular Max sell is 5 ETH.

    uint256 private swapThreshold = (_tTotal * 5) / 10000;
    uint256 private swapAmount = (_tTotal * 25) / 10000;

    uint256 public _buyLiquidityFee = 2; //2%     
    uint256 public _buyReflectionFee = 1; //1%
    uint256 public _buyTreasuryFee = 4; //4%
    uint256 public _buyMarketingFee = 4; //4%
    uint256 public _buyTeamFee = 2; //2%


    uint256 public _sellLiquidityFee = 2; //2%
    uint256 public _sellReflectionFee = 1; //1%
    uint256 public _sellTreasuryFee = 4; //4%
    uint256 public _sellMarketingFee = 4; //4%
    uint256 public _sellTeamFee = 2; //2%

    StaticMaxTax public staticTax = StaticMaxTax({
        maxLiquidity: 2, //2%
        maxReflection: 1, //1%
        maxTreasury: 4, //4%
        maxMarketing: 4, //4%
        maxTeamfee: 2 //2%
    });
    
    uint256 private liquidityFee = _buyLiquidityFee;
    uint256 private treasuryFee = _buyTreasuryFee;
    uint256 private marketingFee = _buyMarketingFee;
    uint256 private teamFee = _buyTeamFee;
    uint256 private reflectionFee=_buyReflectionFee;

    uint256 private totalFee = liquidityFee.add(treasuryFee).add(marketingFee).add(teamFee);
    uint256 private currenttotalFee = totalFee;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwap;

    address[] path;
    
    bool public tradingOpen = false;
    bool public zeroBuyTaxmode = false;
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isMaxWalletExempt[owner()] = true;
        _isMaxWalletExempt[address(this)] = true;
        _isMaxWalletExempt[uniswapV2Pair] = true;
        _isMaxWalletExempt[DEAD] = true;

        path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), MAX);
        _approve(_msgSender(), address(uniswapV2Router), MAX);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen);
        tradingOpen = true;
        excludeFromReward(address(this));
        excludeFromReward(uniswapV2Pair);

        if(tradingOpen && launchedAtBlock == 0){
            launchedAtBlock = block.number;
            launchedAtTime = block.timestamp;
        }
    }
 
    function setZeroBuyTaxmode(bool _status) external onlyOwner() {
       zeroBuyTaxmode = _status;
    }
    
    function setNewRouter(address newRouter) external onlyOwner() {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            uniswapV2Pair = get_pair;
        }
        uniswapV2Router = _newRouter;
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {

        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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
        require(!_isSniper[to], "You are on the sniper list!");
        require(!_isSniper[from], "You are on the sniper list!");
        if (from != owner() && to != owner()) require(tradingOpen, "Trading not yet enabled."); //trading not open yet
        
        bool takeFee = false;

        if (!(_isExcludedFromFee[from] || _isExcludedFromFee[to])) {
            takeFee = true;
        }

        currenttotalFee=totalFee;
        reflectionFee=_buyReflectionFee;

        //max wallet holding
        if(!_isMaxWalletExempt[to] && from != owner() && from == uniswapV2Pair){
            if(zeroBuyTaxmode){
                //adjust max amount according to 0% buy tax
                require(amount + balanceOf(to) <= _maxWalletToken , "Total holding is limited");
            }else{
                //adjust max amount according to tax
                uint256 baseactualfee = _buyReflectionFee.add(_buyLiquidityFee).add(_buyTreasuryFee).add(_buyMarketingFee).add(_buyTeamFee);
                uint256 maxpercent = 100;
                baseactualfee = maxpercent.sub(baseactualfee);
                require(amount.mul(baseactualfee).div(100) + balanceOf(to) <= _maxWalletToken , "Total holding is limited");
            }
        }
        
        if(tradingOpen && to == uniswapV2Pair) { //sell
            reflectionFee = _sellReflectionFee;

            if (maxEthTradesEnabled) {
                uint256 _ethBalance = uniswapV2Router.getAmountsOut(amount, path)[1];
                if(block.timestamp <= launchedAtTime + 24 hours) {
                    require(_ethBalance <= maxEthSell_launch); //max 1 ETH sell for 24 hours.
                }else{
                    require(_ethBalance <= maxEthSell); //max 5 ETH sell after 24 hours.
                }
            }

            //anti-dump structure for the first 24 hours.
            if(block.timestamp <= launchedAtTime + 2 hours) {
                currenttotalFee = 30; //30%
            }else if (block.timestamp <= launchedAtTime + 12 hours) {
                currenttotalFee = 25; //25%
            }else if (block.timestamp <= launchedAtTime + 24 hours) {
                currenttotalFee = 20; //20%
            }else{
                currenttotalFee = _sellLiquidityFee.add(_sellTreasuryFee).add(_sellMarketingFee).add(_sellTeamFee); //12%+1%reflection
            }
        }

        //antisniper - first 5 blocks
        if(launchedAtBlock > 0 && ((launchedAtBlock + deadBlocks) >= block.number)){
                _isSniper[to]=true;
        }

         //on buys only
        if(zeroBuyTaxmode){
             if(tradingOpen && from == uniswapV2Pair) {
                    currenttotalFee=0;
             }
        }

        //sell
        if (!inSwap && tradingOpen && to == uniswapV2Pair) {    
            uint256 contractTokenBalance = balanceOf(address(this));           
            if (contractTokenBalance >= swapThreshold) {
                if(contractTokenBalance >= swapAmount) { 
                    contractTokenBalance = swapAmount; 
                }
                swapTokens(contractTokenBalance);
            }      
        }
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {       
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);       
        swapTokensForEth(amountToSwap);
        uint256 amountETH = address(this).balance;
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);    
        uint256 totalTAXfee = treasuryFee.add(marketingFee).add(teamFee); 
        uint256 amountETHdev = amountETH.mul(totalTAXfee).div(totalETHFee);
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0) {
            sendETHToFee(amountETHdev,devWallet);
        }
        if (amountToLiquify > 0) {
                addLiquidity(amountToLiquify,amountETHLiquidity);
        }
    }
    
    function sendETHToFee(uint256 amount,address payable wallet) private {
        wallet.transfer(amount);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);      
        emit SwapTokensForETH(tokenAmount, path);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {

        uint256 _previousReflectionFee=reflectionFee;
        uint256 _previousTotalFee=currenttotalFee;
        if(!takeFee){
            reflectionFee = 0;
            currenttotalFee = 0;
        }
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee){
            reflectionFee = _previousReflectionFee;
            currenttotalFee = _previousTotalFee;
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
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
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(reflectionFee).div(10**2);
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(currenttotalFee).div(10**2);
    }
    
    function excludeMultiple(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function excludeFromFee(address[] calldata addresses) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isExcludedFromFee[addresses[i]] = true;
        }
    }
     
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setWallets(address _devWallet) external onlyOwner() {
        devWallet = payable(_devWallet);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }
    
    function manage_Snipers(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
                _isSniper[addresses[i]] = status;
        }
    }
         
    function withDrawLeftoverETH(address payable recipient) public onlyOwner {
        recipient.transfer(address(this).balance);
    }

    function withdrawStuckTokens(IERC20 token, address to) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(to, balance);
    }

    function setMaxWalletBase2000(uint256 maxWallet) external onlyOwner() {
        _maxWalletToken = _tTotal.div(2000).mul(maxWallet);
    }

    function setMaxWalletExempt(address _addr) external onlyOwner {
        _isMaxWalletExempt[_addr] = true;
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
    }

    function setTaxesBuy(uint256 _reflectionFee, uint256 _liquidityFee, uint256 _treasuryFee, uint256 _marketingFee, uint256 _teamFee) external onlyOwner {
        require(_reflectionFee <= staticTax.maxReflection && 
        _liquidityFee <= staticTax.maxLiquidity && 
        _marketingFee <= staticTax.maxMarketing &&
        _teamFee <= staticTax.maxTeamfee);
        
        uint256 total_buy_fee = _reflectionFee.add(_liquidityFee).add(_treasuryFee).add(_marketingFee).add(_teamFee);
        require(total_buy_fee <= 13); //Max buy fee 13%

        _buyLiquidityFee = _liquidityFee;
        _buyReflectionFee = _reflectionFee;
        _buyTreasuryFee = _treasuryFee;
        _buyMarketingFee = _marketingFee;
        _buyTeamFee = _teamFee;       

        reflectionFee = _reflectionFee;
        liquidityFee = _liquidityFee;
        treasuryFee = _treasuryFee;
        marketingFee = _marketingFee;
        teamFee = _teamFee;
        totalFee = liquidityFee.add(treasuryFee).add(marketingFee).add(teamFee);
    }

    function setTaxesSell(uint256 _reflectionFee,uint256 _liquidityFee, uint256 _treasuryFee, uint256 _marketingFee, uint256 _teamFee) external onlyOwner {
        require(_reflectionFee <= staticTax.maxReflection && 
        _liquidityFee <= staticTax.maxLiquidity && 
        _marketingFee <= staticTax.maxMarketing &&
        _teamFee <= staticTax.maxTeamfee);
        
        uint256 total_sell_fee = _reflectionFee.add(_liquidityFee).add(_treasuryFee).add(_marketingFee).add(_teamFee);
        require(total_sell_fee <= 13); //Max sell fee 13%

        _sellLiquidityFee = _liquidityFee;
        _sellReflectionFee= _reflectionFee;
        _sellTreasuryFee = _treasuryFee;
        _sellMarketingFee = _marketingFee;
        _sellTeamFee = _teamFee;      
    }

    function setEthLimits(uint256 sellVal) external onlyOwner {
        require(sellVal >= 5 * 10**18);
        maxEthSell = sellVal * 10**18;      
    }

    function setEthLimitsEnabled(bool maxEthTrades) external onlyOwner {
        maxEthTradesEnabled = maxEthTrades;
    }    

    receive() external payable {}
}
