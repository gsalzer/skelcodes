// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITokenDecimals.sol";

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function factory() external view returns (address);

    function WETH() external view returns (address);
}

contract SafuInvestmentsPresale {
    using SafeMath for uint256;

    IUniswapV2Router02 private immutable uniswapRouter;

    address payable internal safuFactoryAddress; // address that creates the presale contracts
    address payable public safuDevAddress; // address where dev fees will be transferred to
    address public safuLiqLockAddress; // address where LP tokens will be locked

    IERC20 public token; // token that will be sold
    address payable public presaleCreatorAddress; // address where percentage of invested wei will be transferred to
    address public unsoldTokensDumpAddress; // address where unsold tokens will be transferred to

    mapping(address => uint256) public investments; // total wei invested per address
    mapping(address => bool) public whitelistedAddresses; // addresses eligible in presale
    mapping(address => bool) public claimed; // if true, it means investor already claimed the tokens or got a refund

    uint256 private safuDevFeePercentage; // dev fee to support the development of Safu Investments
    uint256 private safuMinDevFeeInWei; // minimum fixed dev fee to support the development of Safu Investments
    uint256 public safuId; // used for fetching presale without referencing its address

    uint256 public totalInvestorsCount; // total investors count
    uint256 public totalInvestorsClaimedCount; // total investors claimed count
    uint256 public presaleCreatorClaimWei; // wei to transfer to presale creator per investor claim
    uint256 public totalCollectedWei; // total wei collected
    uint256 public totalTokens; // total tokens to be sold
    uint256 public tokensLeft; // available tokens to be sold
    uint256 public tokenPriceInWei; // token presale wei price per 1 token
    uint256 public hardCapInWei; // maximum wei amount that can be invested in presale
    uint256 public softCapInWei; // minimum wei amount to invest in presale, if not met, invested wei will be returned
    uint256 public maxInvestInWei; // maximum wei amount that can be invested per wallet address
    uint256 public minInvestInWei; // minimum wei amount that can be invested per wallet address
    uint256 public openTime; // time when presale starts, investing is allowed
    uint256 public closeTime; // time when presale closes, investing is not allowed
    uint256 public uniListingPriceInWei; // token price when listed in Uniswap
    uint256 public uniLiquidityAddingTime; // time when adding of liquidity in uniswap starts, investors can claim their tokens afterwards
    uint256 public uniLPTokensLockDurationInDays; // how many days after the liquity is added the presale creator can unlock the LP tokens
    uint256 public uniLiquidityPercentageAllocation; // how many percentage of the total invested wei that will be added as liquidity

    bool public uniLiquidityAdded = false; // if true, liquidity is added in Uniswap and lp tokens are locked
    bool public onlyWhitelistedAddressesAllowed = true; // if true, only whitelisted addresses can invest
    bool public safuDevFeesExempted = false; // if true, presale will be exempted from dev fees
    bool public presaleCancelled = false; // if true, investing will not be allowed, investors can withdraw, presale creator can withdraw their tokens

    bytes32 public saleTitle;
    bytes32 public linkTelegram;
    bytes32 public linkTwitter;
    bytes32 public linkDiscord;
    bytes32 public linkWebsite;

    constructor(
        address _safuFactoryAddress,
        address _safuDevAddress,
        address _uniswapRouter
    ) public {
        require(_safuFactoryAddress != address(0));
        require(_safuDevAddress != address(0));
        require(_uniswapRouter != address(0));

        safuFactoryAddress = payable(_safuFactoryAddress);
        safuDevAddress = payable(_safuDevAddress);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    modifier onlySafuDev() {
        require(safuFactoryAddress == msg.sender || safuDevAddress == msg.sender);
        _;
    }

    modifier onlySafuFactory() {
        require(safuFactoryAddress == msg.sender);
        _;
    }

    modifier onlyPresaleCreatorOrSafuFactory() {
        require(
            presaleCreatorAddress == msg.sender || safuFactoryAddress == msg.sender,
            "Not presale creator or factory"
        );
        _;
    }

    modifier onlyPresaleCreator() {
        require(presaleCreatorAddress == msg.sender, "Not presale creator");
        _;
    }

    modifier whitelistedAddressOnly() {
        require(!onlyWhitelistedAddressesAllowed || whitelistedAddresses[msg.sender], "Address not whitelisted");
        _;
    }

    modifier presaleIsNotCancelled() {
        require(!presaleCancelled, "Cancelled");
        _;
    }

    modifier investorOnly() {
        require(investments[msg.sender] > 0, "Not an investor");
        _;
    }

    modifier notYetClaimedOrRefunded() {
        require(!claimed[msg.sender], "Already claimed or refunded");
        _;
    }

    function setAddressInfo(
        address _presaleCreator,
        address _tokenAddress,
        address _unsoldTokensDumpAddress
    ) external onlySafuFactory {
        require(_presaleCreator != address(0));
        require(_tokenAddress != address(0));
        require(_unsoldTokensDumpAddress != address(0));

        presaleCreatorAddress = payable(_presaleCreator);
        token = IERC20(_tokenAddress);
        unsoldTokensDumpAddress = _unsoldTokensDumpAddress;
    }

    function setGeneralInfo(
        uint256 _totalTokens,
        uint256 _tokenPriceInWei,
        uint256 _hardCapInWei,
        uint256 _softCapInWei,
        uint256 _maxInvestInWei,
        uint256 _minInvestInWei,
        uint256 _openTime,
        uint256 _closeTime
    ) external onlySafuFactory {
        require(_totalTokens > 0);
        require(_tokenPriceInWei > 0);
        require(_hardCapInWei > 0);

        require(_openTime >= block.timestamp);
        require(_closeTime > _openTime && (_closeTime <= block.timestamp + 2 weeks));

        // Hard cap > (token amount * token price)
        require(_hardCapInWei <= _totalTokens.mul(_tokenPriceInWei) && _hardCapInWei >= _tokenPriceInWei);
        // Soft cap > to hard cap
        require(_softCapInWei <= _hardCapInWei);
        //  Min. wei investment > max. wei investment
        require(_minInvestInWei <= _maxInvestInWei);

        totalTokens = _totalTokens;
        tokensLeft = _totalTokens;
        tokenPriceInWei = _tokenPriceInWei;
        hardCapInWei = _hardCapInWei;
        softCapInWei = _softCapInWei;
        maxInvestInWei = _maxInvestInWei;
        minInvestInWei = _minInvestInWei;
        openTime = _openTime;
        closeTime = _closeTime;
    }

    function setUniswapInfo(
        uint256 _uniListingPriceInWei,
        uint256 _uniLiquidityAddingTime,
        uint256 _uniLPTokensLockDurationInDays,
        uint256 _uniLiquidityPercentageAllocation
    ) external onlySafuFactory {
        require(_uniListingPriceInWei > 0);
        require(_uniLiquidityAddingTime > 0);
        require(_uniLPTokensLockDurationInDays > 0);
        require(_uniLiquidityPercentageAllocation > 0);

        require(closeTime > 0);
        require(_uniLiquidityAddingTime >= closeTime);

        uniListingPriceInWei = _uniListingPriceInWei;
        uniLiquidityAddingTime = _uniLiquidityAddingTime;
        uniLPTokensLockDurationInDays = _uniLPTokensLockDurationInDays;
        uniLiquidityPercentageAllocation = _uniLiquidityPercentageAllocation;
    }

    function setStringInfo(
        bytes32 _saleTitle,
        bytes32 _linkTelegram,
        bytes32 _linkDiscord,
        bytes32 _linkTwitter,
        bytes32 _linkWebsite
    ) external onlyPresaleCreatorOrSafuFactory {
        saleTitle = _saleTitle;
        linkTelegram = _linkTelegram;
        linkDiscord = _linkDiscord;
        linkTwitter = _linkTwitter;
        linkWebsite = _linkWebsite;
    }

    function setSafuInfo(
        address _safuLiqLockAddress,
        uint256 _safuDevFeePercentage,
        uint256 _safuMinDevFeeInWei,
        uint256 _safuId
    ) external onlySafuDev {
        safuLiqLockAddress = _safuLiqLockAddress;
        safuDevFeePercentage = _safuDevFeePercentage;
        safuMinDevFeeInWei = _safuMinDevFeeInWei;
        safuId = _safuId;
    }

    function setSafuDevFeesExempted(bool _safuDevFeesExempted) external onlySafuDev {
        safuDevFeesExempted = _safuDevFeesExempted;
    }

    function setOnlyWhitelistedAddressesAllowed(bool _onlyWhitelistedAddressesAllowed)
        external
        onlyPresaleCreatorOrSafuFactory
    {
        onlyWhitelistedAddressesAllowed = _onlyWhitelistedAddressesAllowed;
    }

    function addwhitelistedAddresses(address[] calldata _whitelistedAddresses)
        external
        onlyPresaleCreatorOrSafuFactory
    {
        onlyWhitelistedAddressesAllowed = _whitelistedAddresses.length > 0;
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            whitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return (_weiAmount.mul(10**uint256(ITokenDecimals(address(token)).decimals()))).div(tokenPriceInWei);
    }

    function invest() public payable whitelistedAddressOnly presaleIsNotCancelled {
        require(block.timestamp >= openTime, "Not yet opened");
        require(block.timestamp < closeTime, "Closed");
        require(totalCollectedWei < hardCapInWei, "Hard cap reached");
        uint256 totalInvestmentInWei = investments[msg.sender].add(msg.value);
        require(
            totalInvestmentInWei >= minInvestInWei || totalCollectedWei >= hardCapInWei.sub(1 ether),
            "Min investment not reached"
        );
        require(maxInvestInWei == 0 || totalInvestmentInWei <= maxInvestInWei, "Max investment reached");

        require(tokensLeft > 0 && msg.value > 0 && msg.value <= tokensLeft.mul(tokenPriceInWei));

        if (investments[msg.sender] == 0) {
            totalInvestorsCount = totalInvestorsCount.add(1);
        }

        totalCollectedWei = totalCollectedWei.add(msg.value);
        investments[msg.sender] = totalInvestmentInWei;
        tokensLeft = tokensLeft.sub(getTokenAmount(msg.value));
    }

    receive() external payable {
        invest();
    }

    function addLiquidityAndLockLPTokens() external presaleIsNotCancelled {
        require(totalCollectedWei > 0, "Presale has no funds");
        require(!uniLiquidityAdded, "Liquidity already added");
        require(
            !onlyWhitelistedAddressesAllowed || whitelistedAddresses[msg.sender] || msg.sender == presaleCreatorAddress,
            "Not whitelisted or not presale creator"
        );

        if (totalCollectedWei >= hardCapInWei.sub(1 ether) && block.timestamp < uniLiquidityAddingTime) {
            require(msg.sender == presaleCreatorAddress, "Not presale creator");
        } else if (block.timestamp >= uniLiquidityAddingTime) {
            require(
                msg.sender == presaleCreatorAddress || investments[msg.sender] > 0,
                "Not presale creator or investor"
            );
            require(totalCollectedWei >= softCapInWei, "Soft cap not reached");
        } else {
            revert("Liquidity cannot be added yet");
        }

        uniLiquidityAdded = true;

        uint256 finalTotalCollectedWei = totalCollectedWei;
        uint256 safuDevFeeInWei;
        if (!safuDevFeesExempted) {
            uint256 pctDevFee = finalTotalCollectedWei.mul(safuDevFeePercentage).div(100);
            safuDevFeeInWei = pctDevFee > safuMinDevFeeInWei || safuMinDevFeeInWei >= finalTotalCollectedWei
                ? pctDevFee
                : safuMinDevFeeInWei;
        }
        if (safuDevFeeInWei > 0) {
            finalTotalCollectedWei = finalTotalCollectedWei.sub(safuDevFeeInWei);
            safuDevAddress.transfer(safuDevFeeInWei);
        }

        uint256 liqPoolEthAmount = finalTotalCollectedWei.mul(uniLiquidityPercentageAllocation).div(100);
        uint256 liqPoolTokenAmount = (liqPoolEthAmount.mul(10**uint256(ITokenDecimals(address(token)).decimals()))).div(
            uniListingPriceInWei
        );

        token.approve(address(uniswapRouter), liqPoolTokenAmount);

        uniswapRouter.addLiquidityETH{ value: liqPoolEthAmount }(
            address(token),
            liqPoolTokenAmount,
            0,
            0,
            safuLiqLockAddress,
            block.timestamp.add(15 minutes)
        );

        uint256 unsoldTokensAmount = token.balanceOf(address(this)).sub(getTokenAmount(totalCollectedWei));
        if (unsoldTokensAmount > 0) {
            token.transfer(unsoldTokensDumpAddress, unsoldTokensAmount);
        }

        presaleCreatorClaimWei = address(this).balance.mul(1e18).div(totalInvestorsCount.mul(1e18));
    }

    function claimTokens() external whitelistedAddressOnly presaleIsNotCancelled investorOnly notYetClaimedOrRefunded {
        require(uniLiquidityAdded, "Liquidity not yet added");

        // make sure this goes first before transfer to prevent reentrancy
        claimed[msg.sender] = true;
        uint256 amount = getTokenAmount(investments[msg.sender]);
        uint256 tokenBalance = token.balanceOf(address(this));
        if (amount > tokenBalance) {
            amount = tokenBalance;
        }
        token.transfer(msg.sender, amount);
        totalInvestorsClaimedCount = totalInvestorsClaimedCount.add(1);

        uint256 balance = address(this).balance;
        if (balance > 0) {
            uint256 funds = presaleCreatorClaimWei > balance ? balance : presaleCreatorClaimWei;
            presaleCreatorAddress.transfer(funds);
        }
    }

    function getRefund() external whitelistedAddressOnly investorOnly notYetClaimedOrRefunded {
        if (!presaleCancelled) {
            require(block.timestamp >= openTime, "Not yet opened");
            require(block.timestamp >= closeTime, "Not yet closed");
            require(softCapInWei > 0, "No soft cap");
            require(totalCollectedWei < softCapInWei, "Soft cap reached");
        }

        // make sure this goes first before transfer to prevent reentrancy
        claimed[msg.sender] = true;
        uint256 investment = investments[msg.sender];
        uint256 presaleBalance = address(this).balance;
        require(presaleBalance > 0, "Pre-sale contract has no more funds");

        if (investment > presaleBalance) {
            investment = presaleBalance;
        }

        if (investment > 0) {
            msg.sender.transfer(investment);
        }
    }

    function cancelAndTransferTokensToPresaleCreator() external {
        bool expired = block.timestamp >= (openTime + 2 weeks);
        if (!expired && !uniLiquidityAdded && presaleCreatorAddress != msg.sender && safuDevAddress != msg.sender) {
            revert();
        }
        if (uniLiquidityAdded && safuDevAddress != msg.sender) {
            revert();
        }

        require(!presaleCancelled);
        presaleCancelled = true;

        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(presaleCreatorAddress, balance);
        }
    }

    function collectFundsRaised() external onlyPresaleCreator {
        require(uniLiquidityAdded);
        require(!presaleCancelled);
        require(totalInvestorsClaimedCount >= totalInvestorsCount.div(2), "~50% of the investors haven't claimed yet");

        if (address(this).balance > 0) {
            presaleCreatorAddress.transfer(address(this).balance);
        }
    }
}

