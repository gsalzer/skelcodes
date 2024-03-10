// SPDX-License-Identifier: MIT
//               ╓╔╦╖,
//            ,▒▒▒▒▒▒▒▒▒╦
//            ▒▒▒▒░░░░░░▒▒
//         ,╓╔▒▒▒░░░░░░░░░⌐
//      ,▒▒▒▒▒▒▒▒░░░░░░░▒▒           ,,,,
//      ▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒     ,▄@▓▒▒▒▒▒▒▒▒▓▒╦,
//      ╟▒▒▒▒▒▒▒▒▒▒▒░░░░░▒▒╦,#▓▒▒▓▓▓▓▓▓▓▓▓▒▒▓▒▒▒▒╖
//       ╚▒▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒,
//         ╙▒▒▒▒▒▒▒▒▒▒▒░▒▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▒▒▒╖
//                   ╚▒▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒╖
//                   Æ▓▓█████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▓▒▒▒╦,
//                  ╣▓▓▓███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▒▒▒#╓
//                 ▓▒▓▓▓▓▓███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▓▒▒▒▒╖
//                ╣▓▓▓▓▓▓▓▓▓▓██████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒╖
//               ]▒▓▓▓▓▓▓▓▓▓▓▓███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒╦
//                ▒▒█▓▓▓▓▓▓▓▓▓▓▓▓███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀▀▒▒░▀▀▒▒▒╕
//                ▓▒▓██▓▓▓▓▓▓▓▓▓▓▓▓███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀▒▒▒▒▒▒▒▒▒░░▒▒▒m
//                "▒▒████▓▓▓▓▓▓▓▓▓▓▓▓███████▓▓▓▓▓▓▓▓▓▀░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░╙▒m
//                 ^▒▒▓█████▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓▓▀▀░░░░▒▒▒▒▒▒▒▒░▒░▒▒▒▒▒░░╟▒⌐
//                   ▀▒▓█████▓▓▓▓▓▓▓▓▓▓▓▓██████▀░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒░▒▒░▐▒▒
//                    ▀▒▒▓██████▓▓▓▓▓▓▓▓▓▓▓▓█▓░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒░░▒▒░╫▒
//                     '▀▒▓███████▓▓▓▓▓▓▓▓▓▓▓░▒▒▒▒▒▒░░▒░░▒▒▒▒▒▒░▒▒▒▒▒▒▒▒@▒∩
//                       ╙▓▒▓▓██████▓▓▓▓▓▓▓▓░░▒▒▒░▒▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩
//                         ╙▓▒▓▓███████▓▓▓▓▌░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▒╜
//                           ╙▀▒▒▓███████▓▓░▒▒▒▒▒▒░▒▒▒░▒▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒▒▒▒▒╦,
//                              ╙▀▒▒▓▓████▌░▒▒▒▒▒░▒▒▒▒▒░▒▒▒▒░░░░░░░░░░░░░░░░░░▒▒⌐
//                                 "▀▒▒▓██▌░▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░   ░░░▒▒⌐
//                                    ▀▒▒▓█Q░▒▒▒▒▒▒▒░▒▒▒▒░░░░▒▒▒░░░░░░░░░░░░░░░░▒▒
//                                      ▀▒▒▓▓░▒▒▒▒▒▒▒▒░░░░▄▓▓▌▒▒░░░░░░░░░░░░░░░▒▒
//                                        ╙▀▒▒▓▓▄▄Q░Q▄▄╣▓▒▀╙¬ ▒▒░░░░░░░░░░▒▒▒▒▒╙
//                                           '╙"╙▀▀▀▀▀▀╙└     ▒▒░░░░░░░░░▒▒
//                                                            └▒▒▒▒░░░░░▒▒∩
//                                                              "╝▒▒▒▒▒▒▒`
//
//   An automatic yield and liquidity generation protocol
//
//   10% transaction tax (set slippage!)
//   6.5% to liquidity providers
//   2% to holders
//   1.5% locked to liquidity forever (and ever!)
//
//  Stealth launch. Liquidity locked forever. Ownership renounced. Makes french fries when needed.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

pragma solidity ^0.6.12;

contract FEED is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    address private _burnPool = 0x0000000000000000000000000000000000000000;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;

    string private _name = "https://t.me/feedprotocol";
    string private _symbol = "FEED";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _burnFee = 0;
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _liquidityFee = 8;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _lpRewardFromLiquidityPercent = 80; // 80% from the collected liquidity tax will go to LPs

    uint256 public totalLiquidityProviderRewards;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public BurnLpTokensEnabled = false;
    uint256 public TotalBurnedLpTokens;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 private minTokensBeforeSwap = 100;
    uint256 public tradingEnabledAt = now;

    event RewardLiquidityProviders(uint256 tokenAmount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () public {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

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

    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
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

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool isAddingLiquidity = from == owner() && to == uniswapV2Pair;
        bool isBuy = from == uniswapV2Pair && to != owner();
        bool isSell = from != owner() && to == uniswapV2Pair;

        if ((isBuy || isSell) && tradingEnabledAt + 4 hours > now && amount > 2_000e9) {
            revert("For the first 4 hours, only transactions of max 2.000 tokens are allowed");
        }


        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;

        if (overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled) {
            uint256 lpRewardAmount = contractTokenBalance.mul(_lpRewardFromLiquidityPercent).div(10 ** 2);

            _rewardLiquidityProviders(lpRewardAmount);

            swapAndLiquify(contractTokenBalance.sub(lpRewardAmount));

            if (BurnLpTokensEnabled) {
                burnLpTokens();
            }
        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function burnLpTokens() private {
        IUniswapV2Pair _token = IUniswapV2Pair(uniswapV2Pair);
        uint256 amount = _token.balanceOf(address(this));
        TotalBurnedLpTokens = TotalBurnedLpTokens.add(amount);
        _token.transfer(_burnPool, amount);
    }

    function LpTokenBalance() public view returns (uint256) {
        IUniswapV2Pair token = IUniswapV2Pair(uniswapV2Pair);
        uint256 amount = token.balanceOf(address(this));

        return amount;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee)
            removeAllFee();

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

        if (!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rBurn = tBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rBurn = tBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tTotal = _tTotal.sub(tBurn);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn).sub(tLiquidity);
        return (tTransferAmount, tFee, tBurn, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rLiquidity);
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
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _rewardLiquidityProviders(uint256 liquidityRewards) private {
        _tokenTransfer(address(this), uniswapV2Pair, liquidityRewards, false);
        IUniswapV2Pair(uniswapV2Pair).sync();
        totalLiquidityProviderRewards = totalLiquidityProviderRewards.add(liquidityRewards);
        emit RewardLiquidityProviders(liquidityRewards);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10 ** 2);
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(10 ** 2);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10 ** 2);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _burnFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousBurnFee = _burnFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _burnFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _burnFee = _previousBurnFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setLpRewardFromLiquidityPercent(uint256 percent) external onlyOwner() {
        _lpRewardFromLiquidityPercent = percent;
    }

    function setBurnLpTokenEnabled(bool value) external onlyOwner() {
        BurnLpTokensEnabled = value;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    receive() external payable {}
}

