// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQValidator.sol";
import "../interfaces/IFlashLoanReceiver.sol";

import "../QoreAdmin.sol";

contract QoreTester is QoreAdmin {
    using SafeMath for uint;

    function notifySupplyUpdated(address market, address user) external {
        qDistributor.notifySupplyUpdated(market, user);
    }

    /* ========== CONSTANT VARIABLES ========== */

    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint public constant FLASHLOAN_FEE = 5e14;

    /* ========== STATE VARIABLES ========== */

    mapping(address => address[]) public marketListOfUsers; // (account => qTokenAddress[])
    mapping(address => mapping(address => bool)) public usersOfMarket; // (qTokenAddress => (account => joined))

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Qore_init();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyMemberOfMarket(address qToken) {
        require(usersOfMarket[qToken][msg.sender], "Qore: must enter market");
        _;
    }

    modifier onlyMarket() {
        bool fromMarket = false;
        for (uint i = 0; i < markets.length; i++) {
            if (msg.sender == markets[i]) {
                fromMarket = true;
                break;
            }
        }
        require(fromMarket == true, "Qore: caller should be market");
        _;
    }

    /* ========== VIEWS ========== */

    function allMarkets() external view override returns (address[] memory) {
        return markets;
    }

    function marketInfoOf(address qToken) external view override returns (QConstant.MarketInfo memory) {
        return marketInfos[qToken];
    }

    function marketListOf(address account) external view override returns (address[] memory) {
        return marketListOfUsers[account];
    }

    function checkMembership(address account, address qToken) external view override returns (bool) {
        return usersOfMarket[qToken][account];
    }

    function accountLiquidityOf(address account) external view override returns (uint collateralInUSD, uint supplyInUSD, uint borrowInUSD) {
        return IQValidator(qValidator).getAccountLiquidity(account);
    }

    function distributionInfoOf(address market) external view override returns (QConstant.DistributionInfo memory) {
        return IQDistributor(qDistributor).distributionInfoOf(market);
    }

    function accountDistributionInfoOf(address market, address account) external view override returns (QConstant.DistributionAccountInfo memory) {
        return IQDistributor(qDistributor).accountDistributionInfoOf(market, account);
    }

    function apyDistributionOf(address market, address account) external view override returns (QConstant.DistributionAPY memory) {
        return IQDistributor(qDistributor).apyDistributionOf(market, account);
    }

    function distributionSpeedOf(address qToken) external view override returns (uint supplySpeed, uint borrowSpeed) {
        QConstant.DistributionInfo memory distribution = IQDistributor(qDistributor).distributionInfoOf(qToken);
        return (distribution.supplySpeed, distribution.borrowSpeed);
    }

    function boostedRatioOf(address market, address account) external view override returns (uint boostedSupplyRatio, uint boostedBorrowRatio) {
        return IQDistributor(qDistributor).boostedRatioOf(market, account);
    }

    function accruedQubit(address account) external view override returns (uint) {
        return IQDistributor(qDistributor).accruedQubit(markets, account);
    }

    function accruedQubit(address market, address account) external view override returns (uint) {
        address[] memory _markets = new address[](1);
        _markets[0] = market;
        return IQDistributor(qDistributor).accruedQubit(_markets, account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function enterMarkets(address[] memory qTokens) public override {
        for (uint i = 0; i < qTokens.length; i++) {
            _enterMarket(payable(qTokens[i]), msg.sender);
        }
    }

    function exitMarket(address qToken) external override onlyListedMarket(qToken) onlyMemberOfMarket(qToken) {
        QConstant.AccountSnapshot memory snapshot = IQToken(qToken).accruedAccountSnapshot(msg.sender);
        require(snapshot.borrowBalance == 0, "Qore: borrow balance must be zero");
        require(
            IQValidator(qValidator).redeemAllowed(qToken, msg.sender, snapshot.qTokenBalance),
            "Qore: cannot redeem"
        );

        delete usersOfMarket[qToken][msg.sender];
        _removeUserMarket(qToken, msg.sender);
        emit MarketExited(qToken, msg.sender);
    }

    function supply(address qToken, uint uAmount) external payable override onlyListedMarket(qToken) returns (uint) {
        uAmount = IQToken(qToken).underlying() == address(WBNB) ? msg.value : uAmount;

        uint qAmount = IQToken(qToken).supply{ value: msg.value }(msg.sender, uAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return qAmount;
    }

    function redeemToken(address qToken, uint qAmount) external override onlyListedMarket(qToken) returns (uint) {
        uint uAmountRedeem = IQToken(qToken).redeemToken(msg.sender, qAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return uAmountRedeem;
    }

    function redeemUnderlying(address qToken, uint uAmount) external override onlyListedMarket(qToken) returns (uint) {
        uint uAmountRedeem = IQToken(qToken).redeemUnderlying(msg.sender, uAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return uAmountRedeem;
    }

    function borrow(address qToken, uint amount) external override onlyListedMarket(qToken) {
        _enterMarket(qToken, msg.sender);
        require(IQValidator(qValidator).borrowAllowed(qToken, msg.sender, amount), "Qore: cannot borrow");

        IQToken(payable(qToken)).borrow(msg.sender, amount);
        qDistributor.notifyBorrowUpdated(qToken, msg.sender);
    }

    function repayBorrow(address qToken, uint amount) external payable override onlyListedMarket(qToken) {
        IQToken(payable(qToken)).repayBorrow{ value: msg.value }(msg.sender, amount);
        qDistributor.notifyBorrowUpdated(qToken, msg.sender);
    }

    function repayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable override onlyListedMarket(qToken) {
        IQToken(payable(qToken)).repayBorrowBehalf{ value: msg.value }(msg.sender, borrower, amount);
        qDistributor.notifyBorrowUpdated(qToken, borrower);
    }

    function liquidateBorrow(
        address qTokenBorrowed,
        address qTokenCollateral,
        address borrower,
        uint amount
    ) external payable override nonReentrant {
        amount = IQToken(qTokenBorrowed).underlying() == address(WBNB) ? msg.value : amount;
        require(marketInfos[qTokenBorrowed].isListed && marketInfos[qTokenCollateral].isListed, "Qore: invalid market");
        require(usersOfMarket[qTokenCollateral][borrower], "Qore: not a collateral");
        require(marketInfos[qTokenCollateral].collateralFactor > 0, "Qore: not a collateral");
        require(
            IQValidator(qValidator).liquidateAllowed(qTokenBorrowed, borrower, amount, closeFactor),
            "Qore: cannot liquidate borrow"
        );

        uint qAmountToSeize = IQToken(qTokenBorrowed).liquidateBorrow{ value: msg.value }(
            qTokenCollateral,
            msg.sender,
            borrower,
            amount
        );
        IQToken(qTokenCollateral).seize(msg.sender, borrower, qAmountToSeize);
        qDistributor.notifyTransferred(qTokenCollateral, borrower, msg.sender);
        qDistributor.notifyBorrowUpdated(qTokenBorrowed, borrower);
    }

    function claimQubit() external override nonReentrant {
        qDistributor.claimQubit(markets, msg.sender);
    }

    function claimQubit(address market) external override nonReentrant {
        address[] memory _markets = new address[](1);
        _markets[0] = market;
        qDistributor.claimQubit(_markets, msg.sender);
    }

    function transferTokens(address spender, address src, address dst, uint amount) external override nonReentrant onlyMarket {
        IQToken(msg.sender).transferTokensInternal(spender, src, dst, amount);
        qDistributor.notifyTransferred(msg.sender, src, dst);
    }


    /* ========== RESTRICTED FUNCTION FOR WHITELIST ========== */

    function supplyAndBorrowBehalf(address account, address supplyMarket, uint supplyAmount, address borrowMarket, uint borrowAmount)
    external
    payable
    override
    onlyListedMarket(supplyMarket)
    onlyListedMarket(borrowMarket)
    onlyWhitelisted
    nonReentrant
    returns (uint)
    {
        address underlying = IQToken(supplyMarket).underlying();
        uint uAmount = underlying == address(WBNB) ? msg.value : supplyAmount;

        uint qAmount = IQToken(supplyMarket).supplyBehalf{ value: msg.value }(msg.sender, account, uAmount);

        _enterMarket(supplyMarket, account);

        require(_borrowAllowed(supplyMarket, supplyAmount, borrowMarket, borrowAmount), "Qore: cannot borrow");
        IQToken(borrowMarket).borrow(account, borrowAmount);

        qDistributor.notifySupplyUpdated(supplyMarket, account);
        qDistributor.notifyBorrowUpdated(borrowMarket, account);
        return qAmount;
    }

    function supplyAndBorrowBNB(address account, address supplyMarket, uint supplyAmount, uint borrowAmount)
    external
    payable
    override
    onlyListedMarket(supplyMarket)
    onlyWhitelisted
    nonReentrant
    returns (uint)
    {
        require(borrowAmount <= 5e16, "exceed maximum amount");
        address underlying = IQToken(supplyMarket).underlying();
        uint uAmount = underlying == address(WBNB) ? msg.value : supplyAmount;
        uint qAmount = IQToken(supplyMarket).supplyBehalf{ value: msg.value }(msg.sender, account, uAmount);

        _enterMarket(supplyMarket, account);

        address qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;
        _enterMarket(qBNB, account);

        require(_borrowAllowed(supplyMarket, supplyAmount, qBNB, borrowAmount), "Qore: cannot borrow");
        IQToken(qBNB).borrow(account, borrowAmount); // borrow 0.05 BNB
        // no reward update to reduce gasfee
        // qDistributor.notifySupplyUpdated(supplyMarket, account);
        // qDistributor.notifyBorrowUpdated(0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351, account);

        return qAmount;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _enterMarket(address qToken, address _account) internal onlyListedMarket(qToken) {
        if (!usersOfMarket[qToken][_account]) {
            usersOfMarket[qToken][_account] = true;
            marketListOfUsers[_account].push(qToken);
            emit MarketEntered(qToken, _account);
        }
    }

    function _removeUserMarket(address qTokenToExit, address _account) private {
        require(marketListOfUsers[_account].length > 0, "Qore: cannot pop user market");

        address[] memory updatedMarkets = new address[](marketListOfUsers[_account].length - 1);
        uint counter = 0;
        for (uint i = 0; i < marketListOfUsers[_account].length; i++) {
            if (marketListOfUsers[_account][i] != qTokenToExit) {
                updatedMarkets[counter++] = marketListOfUsers[_account][i];
            }
        }
        marketListOfUsers[_account] = updatedMarkets;
    }

    function _borrowAllowed(address supplyMarket, uint supplyAmount, address borrowMarket, uint borrowAmount) internal view returns (bool){
        // Borrow cap of 0 corresponds to unlimited borrowing
        uint borrowCap = marketInfos[borrowMarket].borrowCap;
        if (borrowCap != 0) {
            uint totalBorrows = IQToken(payable(borrowMarket)).totalBorrow();
            uint nextTotalBorrows = totalBorrows.add(borrowAmount);
            require(nextTotalBorrows < borrowCap, "Qore: market borrow cap reached");
        }

        address[] memory markets = new address[](2);
        markets[0] = supplyMarket;
        markets[1] = borrowMarket;
        uint[] memory prices = priceCalculator.getUnderlyingPrices(markets);
        uint collateralValueInUSD = prices[0].mul(supplyAmount).mul(marketInfos[supplyMarket].collateralFactor).div(1e36);
        uint borrowValueInUSD = prices[1].mul(borrowAmount).div(1e18);

        return collateralValueInUSD >= borrowValueInUSD;
    }
}

