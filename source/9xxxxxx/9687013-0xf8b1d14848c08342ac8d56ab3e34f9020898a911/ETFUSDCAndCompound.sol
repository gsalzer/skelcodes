pragma solidity ^0.4.24;
import "./BasicTokenMintable.sol";
import "./SafeMath.sol";
import "./SimpleOracleAccruedRatioUSDC.sol";
import "./CTokenInterface.sol";

interface ERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract ETFUSDCAndCompound is BasicTokenMintable{
    using SafeMath for uint256;

    uint256 public baseRatio = 100;
    string public constant symbol = "STUSDC";

    // USDC token contract
    ERC20 public StableToken;
    SimpleOracleAccruedRatioUSDC public oracle;
    // Defi contract
    CERC20 public cToken;

    // Roles
    address public bincentiveHot; // i.e., Platform Owner
    address public bincentiveCold;
    address[] public investors; // implicitly first investor is the lead investor
    address public trader;

    address[] public midwayQuiters;
    mapping(address => bool) public midwayQuitRequests;
    uint256 public numProcessedMidwayQuitInvestors;
    uint256 public numAUMDistributedInvestors; // i.e., number of investors that already received AUM

    // Contract(Fund) Status
    // 0: not initialized
    // 1: initialized
    // 2: not enough fund came in in time
    // 3: fundStarted
    // 4: running
    // 5: stoppped
    // 6: closed
    uint256 public fundStatus;

    // Money
    uint256 public currentInvestedAmount;
    uint256 public totalMintedTokenAmount;

    // Fund Parameters
    uint256 public investPaymentDueTime;
    uint256 public percentageOffchainFund;

    // Events
    event Deposit(address indexed investor, uint256 investAmount, uint256 mintedAmount);
    event StartFund(uint256 num_investors, uint256 totalInvestedAmount, uint256 totalMintedTokenAmount);
    event MidwayQuit(address indexed investor, uint256 tokenAmount, uint256 USDCAmount);
    event ReturnAUM(uint256 StableTokenAmount);
    event DistributeAUM(address indexed to, uint256 tokenAmount, uint256 StableTokenAmount);
    // Defi Events
    event MintcUSDC(uint USDCAmount);
    event RedeemcUSDC(uint RedeemcUSDCAmount);

    // Modifiers
    modifier initialized() {
        require(fundStatus == 1);
        _;
    }

    // modifier fundStarted() {
    //     require(fundStatus == 3);
    //     _;
    // }

    modifier running() {
        require(fundStatus == 4);
        _;
    }

    modifier stopped() {
        require(fundStatus == 5);
        _;
    }

    modifier afterStartedBeforeStopped() {
        require((fundStatus >= 3) && (fundStatus < 5));
        _;
    }

    modifier afterStartedBeforeClosed() {
        require((fundStatus >= 3) && (fundStatus < 6));
        _;
    }

    modifier closedOrAborted() {
        require((fundStatus == 6) || (fundStatus == 2));
        _;
    }

    modifier isBincentive() {
        require(
            (msg.sender == bincentiveHot) || (msg.sender == bincentiveCold)
        );
        _;
    }

    modifier isBincentiveCold() {
        require(msg.sender == bincentiveCold);
        _;
    }

    modifier isInvestor() {
        // bincentive is not investor
        require(msg.sender != bincentiveHot);
        require(msg.sender != bincentiveCold);
        require(balances[msg.sender] > 0);
        _;
    }

    // Getter Functions


    // Defi Functions
    function querycUSDCAmount() internal returns(uint256) {
        return cToken.balanceOf(address(this));
    }

    function querycExgRate() internal returns(uint256) {
        return cToken.exchangeRateCurrent();
    }

    function mintcUSDC(uint USDCAmount) internal {

        StableToken.approve(address(cToken), USDCAmount); // approve the transfer
        assert(cToken.mint(USDCAmount) == 0);

        emit MintcUSDC(USDCAmount);
    }

    function redeemcUSDC(uint RedeemcUSDCAmount) internal {

        require(cToken.redeem(RedeemcUSDCAmount) == 0, "something went wrong");

        emit RedeemcUSDC(RedeemcUSDCAmount);
    }


    // Investor Deposit
    function deposit(address investor, uint256 depositUSDCAmount) initialized public {
        require(now < investPaymentDueTime);
        require((investor != bincentiveHot) && (investor != bincentiveCold));

        // Transfer Stable Token to this contract
        // If deposit from bincentive, transferFrom `bincentiveCold`
        // Else transferFrom msg.sender
        if((msg.sender == bincentiveHot) || (msg.sender == bincentiveCold)) {
            require(StableToken.transferFrom(bincentiveCold, address(this), depositUSDCAmount));
        }
        else{
            require(StableToken.transferFrom(msg.sender, address(this), depositUSDCAmount));
        }

        if(balances[investor] == 0) {
            investors.push(investor);
        }
        currentInvestedAmount = currentInvestedAmount.add(depositUSDCAmount);

        // Query Oracle for current BTC / Stable Token pair
        uint256 accruedRatioUSDC = oracle.query();
        // Mint and distribute tokens to investors
        uint256 mintedTokenAmount;
        mintedTokenAmount = depositUSDCAmount.mul(baseRatio).div(accruedRatioUSDC);
        mint(investor, mintedTokenAmount);
        totalMintedTokenAmount = totalMintedTokenAmount.add(mintedTokenAmount);

        emit Deposit(investor, depositUSDCAmount, mintedTokenAmount);
    }

    // Start Investing
    function start() initialized isBincentive public {
        // Send 50% USDC offline
        uint256 amountSentOffline = currentInvestedAmount.mul(percentageOffchainFund).div(100);
        require(StableToken.transfer(trader, amountSentOffline));
        // Sent the rest to Defi
        uint256 amountSentDefi = currentInvestedAmount.sub(amountSentOffline);
        mintcUSDC(amountSentDefi);

        // Start the contract
        fundStatus = 4;
        emit StartFund(investors.length, currentInvestedAmount, totalMintedTokenAmount);
    }

    // Investor request to quit and withdraw
    function requestMidwayQuit() afterStartedBeforeStopped isInvestor public {
        require(midwayQuitRequests[msg.sender] != true);
        require(balances[msg.sender] > 0);

        midwayQuitRequests[msg.sender] = true;
        midwayQuiters.push(msg.sender);
    }

    function processMidwayQuit() afterStartedBeforeClosed isBincentive public {
        if(numProcessedMidwayQuitInvestors == midwayQuiters.length) return;
        // Query Oracle for current BTC / Stable Token pair
        uint256 accruedRatioUSDC = oracle.query();
        address investor;
        uint256 investor_amount;
        uint256 amountUSDCForInvestor;
        // withdraw from Defi, payback investors' share
        // and deposit the rest back to Defi if not closed.
        uint256 totalcUSDCAmount = querycUSDCAmount();
        redeemcUSDC(totalcUSDCAmount);
        for(uint i = numProcessedMidwayQuitInvestors; i < midwayQuiters.length; i++) {
            investor = midwayQuiters[i];
            investor_amount = balances[investor];
            balances[investor] = 0;
            amountUSDCForInvestor = investor_amount.mul(accruedRatioUSDC).div(baseRatio);
            require(StableToken.transfer(investor, amountUSDCForInvestor));
            totalMintedTokenAmount = totalMintedTokenAmount.sub(investor_amount);
            numProcessedMidwayQuitInvestors = numProcessedMidwayQuitInvestors.add(1);
            emit MidwayQuit(investor, investor_amount, amountUSDCForInvestor);
        }

        // Close the contract if every investor has quit
        if(numProcessedMidwayQuitInvestors == investors.length) {
            fundStatus = 6;
        } else {
            uint256 leftoverUSDCBalance;
            leftoverUSDCBalance = StableToken.balanceOf(address(this));
            mintcUSDC(leftoverUSDCBalance);
        }
    }

    // Return AUM
    function returnAUM(uint256 stableTokenAmount) running isBincentiveCold public {
        // Option 1: contract transfer AUM directly from trader
        require(StableToken.transferFrom(trader, address(this), stableTokenAmount));
        // Option 2: trader transfer AUM to bincentiveCold and the contract transfer AUM from bincentiveCold
        // require(StableToken.transferFrom(bincentiveCold, address(this), stableTokenAmount));

        // withdraw all funds from Defi
        uint256 totalcUSDCAmount;
        totalcUSDCAmount = querycUSDCAmount();
        redeemcUSDC(totalcUSDCAmount);

        emit ReturnAUM(stableTokenAmount);

        fundStatus = 5;
    }

    // Distribute AUM
    function distributeAUM(uint256 numInvestorsToDistribute) stopped isBincentive public {
        require(numAUMDistributedInvestors.add(numInvestorsToDistribute) <= investors.length, "Distributing to more than total number of investors");

        // Query Oracle for current BTC / Stable Token pair
        uint256 accruedRatioUSDC = oracle.query();

        uint256 stableTokenDistributeAmount;
        address investor;
        uint256 investor_amount;
        // Distribute Stable Token to investors
        for(uint i = numAUMDistributedInvestors; i < (numAUMDistributedInvestors.add(numInvestorsToDistribute)); i++) {
            investor = investors[i];
            if(midwayQuitRequests[investor]) continue;
            investor_amount = balances[investor];
            balances[investor] = 0;
            emit Transfer(investor, address(0), investor_amount);

            stableTokenDistributeAmount = investor_amount.mul(accruedRatioUSDC).div(baseRatio);
            require(StableToken.transfer(investor, stableTokenDistributeAmount));

            emit DistributeAUM(investor, investor_amount, stableTokenDistributeAmount);
        }

        numAUMDistributedInvestors = numAUMDistributedInvestors.add(numInvestorsToDistribute);
        // If all investors have received AUM, then close the fund.
        if(numAUMDistributedInvestors >= investors.length) {
            currentInvestedAmount = 0;
            fundStatus = 6;
        }
    }

    function claimWronglyTransferredFund() closedOrAborted isBincentive public {
        // withdraw leftover funds from Defi
        uint256 totalcUSDCAmount;
        totalcUSDCAmount = querycUSDCAmount();
        redeemcUSDC(totalcUSDCAmount);

        uint256 leftOverAmount = StableToken.balanceOf(address(this));
        if(leftOverAmount > 0) {
            require(StableToken.transfer(bincentiveCold, leftOverAmount));
        }
    }


    // Constructor
    constructor(
        address _oracle,
        address _StableToken,
        address _cToken,
        address _bincentiveHot,
        address _bincentiveCold,
        address _trader,
        uint256 _investPaymentPeriod,
        uint256 _percentageOffchainFund) public {

        oracle = SimpleOracleAccruedRatioUSDC(_oracle);
        bincentiveHot = _bincentiveHot;
        bincentiveCold = _bincentiveCold;
        StableToken = ERC20(_StableToken);
        cToken = CERC20(_cToken);

        trader = _trader;

        // Set parameters
        investPaymentDueTime = now.add(_investPaymentPeriod);
        percentageOffchainFund = _percentageOffchainFund;

        // Initialized the contract
        fundStatus = 1;
    }
}
