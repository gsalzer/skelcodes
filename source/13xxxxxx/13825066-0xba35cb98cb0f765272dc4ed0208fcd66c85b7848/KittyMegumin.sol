// TELEGRAM : https://t.me/meguminkittyerc20
// WEBSITE  : https://www.meguminkitty.fun/
// TWITTER  : https://twitter.com/MeguminKitty

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.4;

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    address _token;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // 0xc778417e063141139fce010982780140aa0cd5ab ropsten
    IUniswapV2Router router;                                   // 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2 MAINNET WETH                 

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 24 hours;
    uint256 public minDistribution = 1 * (10 ** 18) / (100); // Minimum sending is 0.01 ETH

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
            ? IUniswapV2Router(_router)
            : IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        totalDividends = totalDividends.add(msg.value);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(msg.value).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }
    
    function TimeLeftToDistribute(address shareholder) public view returns (uint256) {
        uint256 timeleft;
        if (shareholderClaims[shareholder] + minPeriod > block.timestamp) {
            timeleft = shareholderClaims[shareholder] + minPeriod - block.timestamp;
        } else {
            timeleft = 0;
        }
        return timeleft;
    }

    function distributeDividend(address shareholder) public payable {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract KittyMegumin is IERC20, Auth {
    using SafeMath for uint256;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Megumin Kitty";
    string constant _symbol = "$MEGUMIN";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100_000_000_000_000 * (10 ** _decimals);
    uint256 public _maxBuyTxAmount = _totalSupply * 1/100;
    uint256 public _maxSellTxAmount = _maxBuyTxAmount;
    uint256 public _maxWalletAmount = _maxBuyTxAmount;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => uint256) private _buyMap;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isMaxWalletExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    
    uint256 public reflectionFee = 200;
    uint256 public marketingFee = 800;
    uint256 public liquidityFee = 100;
    uint256 public devFee = 150;
    // 25% fee
    uint256 public constant AD_24HR_reflectionFee = 400;
    uint256 public constant AD_24HR_marketingFee = 1800; // 18%
    uint256 public constant AD_24HR_liquidityFee = 100;
    uint256 public constant AD_24HR_devFee = 200; // 2%
    
    uint256 public totalFee = reflectionFee.add(marketingFee).add(liquidityFee).add(devFee);
    uint256 public AD_24HR_totalFee = AD_24HR_reflectionFee.add(AD_24HR_marketingFee).add(AD_24HR_liquidityFee).add(AD_24HR_devFee);
    address public marketingFeeReceiver;
    address public devFeeReceiver;
    address public liquidityFeeReceiver;
    
    IUniswapV2Router public router;
    address public pair;
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    
    DividendDistributor public distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000; // 0.005%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    bool public tradingOn = false;
    
    constructor () Auth(msg.sender) {
        router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _allowances[address(this)][address(router)] = uint256(-1);
        pair = IUniswapV2Factory(router.factory()).createPair(WETH, address(this));
        distributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        
        isMaxWalletExempt[msg.sender] = true;
        isMaxWalletExempt[pair] = true;
        isMaxWalletExempt[address(this)] = true;
        isMaxWalletExempt[DEAD] = true;
        isMaxWalletExempt[marketingFeeReceiver] = true;
        
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[marketingFeeReceiver] = true;
        
        marketingFeeReceiver = 0x8A722DE0803e0048E807A0BEe0f0a179d7EDB4c3;
        devFeeReceiver = 0x4cFB05091aEBbDF0a74F5d843a9D6E988FC563a2;
        liquidityFeeReceiver = msg.sender;
        
        automatedMarketMakerPairs[pair] = true;
        
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        return distributor.getUnpaidEarnings(shareholder);
    }
    
    function claimDividend() public {
        distributor.claimDividend();
    }
    
    function TimeLeftToDistribute(address shareholder) public view returns (uint256) {
        return distributor.TimeLeftToDistribute(shareholder);
    }
    
    function totalShares() public view returns (uint256) {
        return distributor.totalShares();
    }
    
    function totalDividends() public view returns (uint256) {
        return distributor.totalDividends();
    }
    
    function totalDistributed() public view returns (uint256) {
        return distributor.totalDistributed();
    }
    
    function dividendsPerShare() public view returns (uint256) {
        return distributor.dividendsPerShare();
    }
    
    function minDistribution() public view returns (uint256) {
        return distributor.minDistribution();
    }
    
    // making functions to get distributor info for website

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    
    // Turn on trading (it can't be turend off again)
    function enableTrading() public onlyOwner {
        if (!tradingOn) {
            tradingOn = true;
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        if (sender != owner && recipient != owner) {
            require(tradingOn, "Trading is not turned on yet");
        }
        
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, recipient, amount);
    
        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        if (_isBuy(sender) && _buyMap[recipient] == 0) {
            _buyMap[recipient] = block.timestamp;
        }
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        checkWalletLimit(recipient);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if (automatedMarketMakerPairs[sender]) {
             if (!isTxLimitExempt[recipient]) {
                require(amount <= _maxBuyTxAmount, "TX Limit Exceeded");
             }
             
             if (!isMaxWalletExempt[recipient]) {
                require((_balances[recipient] + amount) <= _maxWalletAmount, "Wallet Amount Limit Exceeded");
             }
        } else if (automatedMarketMakerPairs[recipient]) {
            if (!isTxLimitExempt[sender]) {
                require(amount <= _maxSellTxAmount);
            }
        }
    }

    function checkWalletLimit(address recipient) internal view {
        require(_balances[recipient] <= _maxWalletAmount || isMaxWalletExempt[recipient], "Wallet Amount Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
    
    function _isBuy(address _sender) private view returns (bool) {
        return _sender == pair;
    }

    function originalPurchase(address account) public  view returns (uint256) {
        return _buyMap[account];
    }
    // -----------------------------------------------------------------------------------
    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        // ADD ANTI DUMP
        uint256 feeAmount;
        if (originalPurchase(sender) !=0 &&
            ((originalPurchase(sender) + (10 minutes)) >= block.timestamp)) {
                feeAmount = amount.mul(AD_24HR_totalFee).div(10000);
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }
        else {
             feeAmount = amount.mul(totalFee).div(10000);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = _balances[address(this)];

        uint256 amountReflection = amountToSwap.mul(reflectionFee).div(totalFee);
        uint256 amountMarketing = amountToSwap.mul(marketingFee).div(totalFee);
        uint256 amountDev = amountToSwap.mul(devFee).div(totalFee);
        uint256 amountLiquidity = amountToSwap.mul(liquidityFee).div(totalFee);
 
        swapAndSendToMarketing(amountMarketing);
        swapAndSendToRef(amountReflection);
        swapAndLiquify(amountLiquidity);
        swapAndSendToDev(amountDev);
    }
    // -----------------------------------------------------------------------------------
    function swapAndSendToMarketing(uint256 tokens) private  {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newETHBalance = address(this).balance.sub(initialETHBalance);
        payable(marketingFeeReceiver).transfer(newETHBalance);
    }
    
    function swapAndSendToDev(uint256 tokens) private  {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newETHBalance = address(this).balance.sub(initialETHBalance);
        payable(devFeeReceiver).transfer(newETHBalance);
    }

    function swapAndSendToRef(uint256 tokens) private  {

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(tokens);
        uint256 newETHBalance = address(this).balance.sub(initialETHBalance);
        
        try distributor.deposit{value: newETHBalance}() {} catch {}
    }
    
    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherhalf = tokens.sub(half);
        
        uint256 initialBalance = address(this).balance;
        
        swapTokensForEth(half);

        uint256 newBalance =  address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherhalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherhalf);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {

        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
       router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityFeeReceiver,
            block.timestamp
        );
        
    }
    
    function setTx_Wallet_Limits(uint256 maxBuyTxAmount, uint256 maxSellTxAmount, uint256 maxWalletAmt) external authorized {
        require(maxBuyTxAmount >= 500000, "Maxbuy cant be below 0.5%");
        require(maxSellTxAmount >= 500000, "Maxsell cant be below 0.5%");
        _maxBuyTxAmount = maxBuyTxAmount * (10 ** _decimals);
        _maxSellTxAmount = maxSellTxAmount * (10 ** _decimals);
        _maxWalletAmount = maxWalletAmt * (10 ** _decimals);
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsMaxWalletExempt(address holder, bool exempt) external authorized {
        isMaxWalletExempt[holder] = exempt;
    }

    function setFees(uint256 _reflectionFee, uint256 _marketingFee, uint256 _liquidityFee, uint256 _devFee) external authorized {
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        liquidityFee = _liquidityFee;
        devFee = _devFee; 
        totalFee = _reflectionFee.add(_marketingFee).add(_liquidityFee).add(_devFee);
    }

    function setWalletFeeReceivers(address _marketingFeeReceiver, address _devFeeReceiver) external authorized {
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount * (10 ** _decimals);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    
    function setAutomatedMarketMakerPair(address _pair, bool value) public onlyOwner {
        require(_pair != pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(_pair, value);
        isMaxWalletExempt[pair] = true;
        isDividendExempt[pair] = true;
    }

    function _setAutomatedMarketMakerPair(address _pair, bool value) private {
        require(automatedMarketMakerPairs[_pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[_pair] = value;

        if(value) {
            isDividendExempt[_pair] = true;
        }

        emit SetAutomatedMarketMakerPair(_pair, value);
    }
    // will only be used if the factory fucks up on launch and calculates the wrong pair.
    function setpair(address _pair) public onlyOwner {
        automatedMarketMakerPairs[_pair] = true;
        isMaxWalletExempt[_pair] = true;
        isDividendExempt[_pair] = true;
        pair = _pair;
    }
    
}
