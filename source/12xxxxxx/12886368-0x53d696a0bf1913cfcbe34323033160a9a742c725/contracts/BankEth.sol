// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IFTPAntiBot.sol";

contract BankEth is ERC20, Ownable {
    using SafeMath for uint256;

    IFTPAntiBot private antiBot;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;
    bool private reinvesting;
    bool public antibotEnabled = false;
    bool public maxPurchaseEnabled = true;

    BankEthDividendTracker public dividendTracker;

    address payable public devAddress = 0x7555De0c971C73C85460F5Fb6f53aA6c4FCD7FAE;
    
    uint256 public maxDailyTransferAmount = 2000000 * (10**18);
    uint256 public swapTokensAtAmount = 200000 * (10**18);

    uint256 public immutable bankFee = 10;
    uint256 public immutable devFee = 1;
    uint256 public immutable totalFee = 11;
    
    uint256 public tradingStartTime = 1657685042;

    uint256 minimumTokenBalanceForDividends = 10000 * (10**18);

    //maximum purchase amount for initial launch
    uint256 maxPurchaseAmount = 5000000 * (10**18);

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // addresses that can make transfers before presale is over
    mapping (address => bool) public canTransferBeforeTradingIsEnabled;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
    
    // store the amount traded for each account every day 
    // to ensure that the account has not exceeded the daily threshold
    mapping (uint256 => mapping(address => uint256)) public dailyTransfers;

    // the last time an address transferred
    // used to detect if an account can be reinvest inactive funds to the vault
    mapping (address => uint256) public lastTransfer;
    
    mapping (address => bool) public isExcludedFromDailyLimit;
    
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SendDividends(uint256 amount);
    event DividendClaimed(uint256 ethAmount, uint256 tokenAmount, address account);

    constructor() public ERC20("BankEth", "BANKETH") {
        IFTPAntiBot _antiBot = IFTPAntiBot(0x590C2B20f7920A2D21eD32A21B616906b4209A43);
        antiBot = _antiBot;

    	dividendTracker = new BankEthDividendTracker();
    	
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        // enable owner and fixed-sale wallet to send tokens before presales are over
        canTransferBeforeTradingIsEnabled[owner()] = true;

        isExcludedFromDailyLimit[address(this)] = true;
        isExcludedFromDailyLimit[owner()] = true;

        _mint(owner(), 1000000000 * (10**18));
    }

    receive() external payable {

  	}
  	
  	function setTradingStartTime(uint256 newStartTime) public onlyOwner {
  	    require(tradingStartTime > block.timestamp, "Trading has already started");
  	    require(newStartTime > block.timestamp, "Start time must be in the future");
  	    
  	    tradingStartTime = newStartTime;
  	}
  	
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "BankEth: The dividend tracker already has that address");

        BankEthDividendTracker newDividendTracker = BankEthDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "BankEth: The new dividend tracker must be owned by the BankEth token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "BankEth: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "BankEth: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BankEth: The UniSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BankEth: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function excludeFromDailyLimit(address account, bool excluded) public onlyOwner {
        require(isExcludedFromDailyLimit[account] != excluded, "BankEth: Daily limit exclusion is already the value of 'excluded'");
        isExcludedFromDailyLimit[account] = excluded;
    }

    function allowPreTrading(address account, bool allowed) public onlyOwner {
        // used for owner and pre sale addresses
        require(canTransferBeforeTradingIsEnabled[account] != allowed, "BankEth: Pre trading is already the value of 'excluded'");
        canTransferBeforeTradingIsEnabled[account] = allowed;
    }

    function setMaxPurchaseEnabled(bool enabled) public onlyOwner {
        require(maxPurchaseEnabled != enabled, "BankEth: Max purchase enabled is already the value of 'enabled'");
        maxPurchaseEnabled = enabled;
    }

    function setMaxPurchaseAmount(uint256 newAmount) public onlyOwner {
        maxPurchaseAmount = newAmount;
    }

    function updateDevAddress(address payable newAddress) public onlyOwner {
        devAddress = newAddress;
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

    function reinvestInactive(address payable account) public onlyOwner {
        uint256 tokenBalance = dividendTracker.balanceOf(account);
        require(tokenBalance <= minimumTokenBalanceForDividends, "BankEth: Account balance must be less then minimum token balance for dividends");

        uint256 _lastTransfer = lastTransfer[account];
        require(block.timestamp.sub(_lastTransfer) > 12 weeks, "BankEth: Account must have been inactive for at least 12 weeks");
        		
        dividendTracker.processAccount(account, address(this));
        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if(success) {
   	 		emit SendDividends(dividends);
            try dividendTracker.setBalance(account, 0) {} catch {}        
        }
    }

    function claim(bool reinvest, uint256 minTokens) external {
        _claim(msg.sender, reinvest, minTokens);
    }
    
    function _claim(address payable account, bool reinvest, uint256 minTokens) private {
        uint256 withdrawableAmount = dividendTracker.withdrawableDividendOf(account);
        require(withdrawableAmount > 0, "BankEth: Claimer has no withdrawable dividend");

        if (!reinvest) {
            uint256 ethAmount = dividendTracker.processAccount(account, account);
            if (ethAmount > 0) {
                emit DividendClaimed(ethAmount, 0, account);
            }
            return;
        }
        
		uint256 ethAmount = dividendTracker.processAccount(account, address(this));
	
		if (ethAmount > 0) {
		    reinvesting = true;
		    uint256 tokenAmount = swapEthForTokens(ethAmount, minTokens, account);
		    reinvesting = false;
		    emit DividendClaimed(ethAmount, tokenAmount, account);
        }
    }
    
    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    function getAccount(address _account)
        public view returns (
            uint256 withdrawableDividends,
            uint256 withdrawnDividends,
            uint256 balance
            ) {
        (withdrawableDividends, withdrawnDividends) = dividendTracker.getAccount(_account);
        return (withdrawableDividends, withdrawnDividends, balanceOf(_account));
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // address must be permitted to transfer before tradingStartTime
        if(tradingStartTime > block.timestamp) {
            require(canTransferBeforeTradingIsEnabled[from], "BankEth: This account cannot send tokens until trading is enabled");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if(antibotEnabled) {
            if(automatedMarketMakerPairs[from]){
                require(!antiBot.scanAddress(to, from, tx.origin), "Beep Beep Boop, You're a piece of poop");                                          
            }
            if(automatedMarketMakerPairs[to]){
                require(!antiBot.scanAddress(from, to, tx.origin), "Beep Beep Boop, You're a piece of poop");                                          
            }
        }

        // make sure that the sender has not exceeded their daily transfer limit
        // automated market pairs do not have a daily transfer limit
        if (!isExcludedFromDailyLimit[from] && !automatedMarketMakerPairs[from]) {
            require(dailyTransfers[getDay()][from].add(amount) <= maxDailyTransferAmount, "BankEth: This account has exceeded max daily limit");
        }
        dailyTransfers[getDay()][from] = dailyTransfers[getDay()][from].add(amount);

        // make sure amount does not exceed max on a purchase
        if (maxPurchaseEnabled && !isExcludedFromDailyLimit[to] && automatedMarketMakerPairs[from]) {
            require(amount <= maxPurchaseAmount, "BankEth: Exceeds max purchase amount");
        }

		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            canSwap &&
            !swapping &&
            !reinvesting &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapAndDistribute();
            swapping = false;
        }


        bool takeFee = !swapping && !reinvesting;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        // don't take a fee unless it's a buy / sell
        if((_isExcludedFromFees[from] || _isExcludedFromFees[to]) || (!automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to])) {
            takeFee = false;
        }

        if(takeFee) {
        	uint256 fees = amount.mul(totalFee).div(100);
        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}        
        
        if(antibotEnabled) {
            antiBot.registerBlock(from, to);
        }

        lastTransfer[from] = block.timestamp;
        lastTransfer[to] = block.timestamp;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
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
    
    function swapEthForTokens(uint256 ethAmount, uint256 minTokens, address account) internal returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        uint256 balanceBefore = balanceOf(account);
        
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            minTokens,
            path,
            account,
            block.timestamp
        );
        
        uint256 tokenAmount = balanceOf(account).sub(balanceBefore);
        return tokenAmount;
    }
    
    function swapAndDistribute() private {
        uint256 tokenBalance = balanceOf(address(this));
        swapTokensForEth(tokenBalance);
        
        uint256 ethBalance = address(this).balance;
        uint256 devPortion = ethBalance.mul(devFee).div(totalFee);
        devAddress.transfer(devPortion);

        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if(success) {
   	 		emit SendDividends(dividends);
        }
    }
    
    function assignAntiBot(address _address) external onlyOwner() {
        IFTPAntiBot _antiBot = IFTPAntiBot(_address);                 
        antiBot = _antiBot;
    }
    
    function toggleAntiBot() external onlyOwner() {
        if(antibotEnabled){
            antibotEnabled = false;
        }
        else{
            antibotEnabled = true;
        }
    }

    function getDay() internal view returns(uint256){
        return block.timestamp.div(1 days);
    }
}

contract BankEthDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    mapping (address => bool) public excludedFromDividends;

    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);

    constructor() public DividendPayingToken("BankEth_Dividend_Tracker", "BankEth_Dividend_Tracker") {
        minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 10000+ tokens
    }

    function _approve(address, address, uint256) internal override {
        require(false, "BankEth_Dividend_Tracker: No approvals allowed");
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "BankEth_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "BankEth_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BankEth contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}
    }

    function processAccount(address payable account, address payable toAccount) public onlyOwner returns (uint256) {
        uint256 amount = _withdrawDividendOfUser(account, toAccount);
        return amount;
    }
}

