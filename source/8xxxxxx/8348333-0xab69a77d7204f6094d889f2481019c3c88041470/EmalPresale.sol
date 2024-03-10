pragma solidity 0.4.24;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract EmalToken {
    // add function prototypes of only those used here
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    function getPresaleAmount() public view returns(uint256);
}

contract EmalWhitelist {
    // add function prototypes of only those used here
    function isWhitelisted(address investorAddr) public view returns(bool whitelisted);
}


contract EmalPresale is Ownable, Pausable {

    using SafeMath for uint256;

    // Start and end timestamps
    uint256 public startTime;
    uint256 public endTime;

    // The token being sold
    EmalToken public token;

    // Whitelist contract used to store whitelisted addresses
    EmalWhitelist public list;

    // Address where funds are collected
    address public multisigWallet;

    // Hard cap in EMAL tokens
    uint256 public hardCap;

    // Amount of tokens that were sold to ether investors plus tokens allocated to investors for fiat and btc investments.
    uint256 public totalTokensSoldandAllocated = 0;



    // Investor contributions made in ether
    mapping(address => uint256) public etherInvestments;

    // Tokens given to investors who sent ether investments
    mapping(address => uint256) public tokensSoldForEther;

    // Total ether raised by the Presale
    uint256 public totalEtherRaisedByPresale = 0;

    // Total number of tokens sold to investors who made payments in ether
    uint256 public totalTokensSoldByEtherInvestments = 0;

    // Count of allocated tokens  for each investor or bounty user
    mapping(address => uint256) public allocatedTokens;

    // Count of total number of EML tokens that have been currently allocated to Presale investors
    uint256 public totalTokensAllocated = 0;



   /** @dev Event for EML token purchase using ether
     * @param investorAddr Address that paid and got the tokens
     * @param paidAmount The amount that was paid (in wei)
     * @param tokenCount The amount of tokens that were bought
     */
    event TokenPurchasedUsingEther(address indexed investorAddr, uint256 paidAmount, uint256 tokenCount);

    /** @dev Event fired when EML tokens are allocated to an investor account
      * @param beneficiary Address that is allocated tokens
      * @param tokenCount The amount of tokens that were allocated
      */
    event TokensAllocated(address indexed beneficiary, uint256 tokenCount);
    event TokensDeallocated(address indexed beneficiary, uint256 tokenCount);


    /** @dev variables and functions which determine conversion rate from ETH to EML
      * based on bonuses and current timestamp.
      */
    uint256 priceOfEthInUSD = 450;
    uint256 bonusPercent1 = 35;
    uint256 priceOfEMLTokenInUSDPenny = 60;
    uint256 overridenBonusValue = 0;

    function setExchangeRate(uint256 overridenValue) public onlyOwner returns(bool) {
        require( overridenValue > 0 );
        require( overridenValue != priceOfEthInUSD);
        priceOfEthInUSD = overridenValue;
        return true;
    }

    function getExchangeRate() public view returns(uint256){
        return priceOfEthInUSD;
    }

    function setOverrideBonus(uint256 overridenValue) public onlyOwner returns(bool) {
        require( overridenValue > 0 );
        require( overridenValue != overridenBonusValue);
        overridenBonusValue = overridenValue;
        return true;
    }

    /** @dev public function that is used to determine the current rate for ETH to EML conversion
      * @return The current token rate
      */
    function getRate() public view returns(uint256) {
        require(priceOfEMLTokenInUSDPenny > 0 );
        require(priceOfEthInUSD > 0 );
        uint256 rate;

        if(overridenBonusValue > 0){
            rate = priceOfEthInUSD.mul(100).div(priceOfEMLTokenInUSDPenny).mul(overridenBonusValue.add(100)).div(100);
        } else {
            rate = priceOfEthInUSD.mul(100).div(priceOfEMLTokenInUSDPenny).mul(bonusPercent1.add(100)).div(100);
        }
        return rate;
    }


    /** @dev Initialise the Presale contract.
      * (can be removed for testing) _startTime Unix timestamp for the start of the token sale
      * (can be removed for testing) _endTime Unix timestamp for the end of the token sale
      * @param _multisigWallet Ethereum address to which the invested funds are forwarded
      * @param _token Address of the token that will be rewarded for the investors
      * @param _list contains a list of investors who completed KYC procedures.
      */
    constructor(uint256 _startTime, uint256 _endTime, address _multisigWallet, address _token, address _list) public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_multisigWallet != address(0));
        require(_token != address(0));
        require(_list != address(0));

        startTime = _startTime;
        endTime = _endTime;
        multisigWallet = _multisigWallet;
        owner = msg.sender;
        token = EmalToken(_token);
        list = EmalWhitelist(_list);
        hardCap = token.getPresaleAmount();
    }

    /** @dev Fallback function that can be used to buy tokens.
      */
    function() external payable {
        if (list.isWhitelisted(msg.sender)) {
            buyTokensUsingEther(msg.sender);
        } else {
            /* Do not accept ETH */
            revert();
        }
    }

    /** @dev Function for buying EML tokens using ether
      * @param _investorAddr The address that should receive bought tokens
      */
    function buyTokensUsingEther(address _investorAddr) internal whenNotPaused {
        require(_investorAddr != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;
        uint256 returnToSender = 0;

        // final rate after including rate value and bonus amount.
        uint256 finalConversionRate = getRate();

        // Calculate EML token amount to be transferred
        uint256 tokens = weiAmount.mul(finalConversionRate);

        // Distribute only the remaining tokens if final contribution exceeds hard cap
        if (totalTokensSoldandAllocated.add(tokens) > hardCap) {
            tokens = hardCap.sub(totalTokensSoldandAllocated);
            weiAmount = tokens.div(finalConversionRate);
            returnToSender = msg.value.sub(weiAmount);
        }

        // update state and balances
        etherInvestments[_investorAddr] = etherInvestments[_investorAddr].add(weiAmount);
        tokensSoldForEther[_investorAddr] = tokensSoldForEther[_investorAddr].add(tokens);
        totalTokensSoldByEtherInvestments = totalTokensSoldByEtherInvestments.add(tokens);
        totalEtherRaisedByPresale = totalEtherRaisedByPresale.add(weiAmount);
        totalTokensSoldandAllocated = totalTokensSoldandAllocated.add(tokens);


        // assert implies it should never fail
        assert(token.transferFrom(owner, _investorAddr, tokens));
        emit TokenPurchasedUsingEther(_investorAddr, weiAmount, tokens);

        // Forward funds
        multisigWallet.transfer(weiAmount);

        // Return funds that are over hard cap
        if (returnToSender > 0) {
            msg.sender.transfer(returnToSender);
        }
    }

    /**
     * @dev Internal function that is used to check if the incoming purchase should be accepted.
     * @return True if the transaction can buy tokens
     */
    function validPurchase() internal view returns(bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool minimumPurchase = msg.value >= 1*(10**18);
        bool hardCapNotReached = totalTokensSoldandAllocated < hardCap;
        return withinPeriod && hardCapNotReached && minimumPurchase;
    }

    /** @dev Public function to check if Presale isActive or not
      * @return True if Presale event has ended
      */
    function isPresaleActive() public view returns(bool) {
        if (!paused && now>startTime && now<endTime && totalTokensSoldandAllocated<=hardCap){
            return true;
        } else {
            return false;
        }
    }

    /** @dev Gets the balance of the specified address.
      * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOfEtherInvestor(address _owner) external view returns(uint256 balance) {
        require(_owner != address(0));
        return etherInvestments[_owner];
    }

    function getTokensSoldToEtherInvestor(address _owner) public view returns(uint256 balance) {
        require(_owner != address(0));
        return tokensSoldForEther[_owner];
    }




    /** @dev BELOW ARE FUNCTIONS THAT HANDLE INVESTMENTS IN FIAT AND BTC.
      * functions are automatically called by ICO Sails.js app.
      */


    /** @dev Allocates EML tokens to an investor address called automatically
      * after receiving fiat or btc investments from KYC whitelisted investors.
      * @param beneficiary The address of the investor
      * @param tokenCount The number of tokens to be allocated to this address
      */
    function allocateTokens(address beneficiary, uint256 tokenCount) public onlyOwner returns(bool success) {
        require(beneficiary != address(0));
        require(validAllocation(tokenCount));

        uint256 tokens = tokenCount;

        /* Allocate only the remaining tokens if final contribution exceeds hard cap */
        if (totalTokensSoldandAllocated.add(tokens) > hardCap) {
            tokens = hardCap.sub(totalTokensSoldandAllocated);
        }

        /* Update state and balances */
        allocatedTokens[beneficiary] = allocatedTokens[beneficiary].add(tokens);
        totalTokensSoldandAllocated = totalTokensSoldandAllocated.add(tokens);
        totalTokensAllocated = totalTokensAllocated.add(tokens);

        // assert implies it should never fail
        assert(token.transferFrom(owner, beneficiary, tokens));
        emit TokensAllocated(beneficiary, tokens);

        return true;
    }

    function validAllocation( uint256 tokenCount ) internal view returns(bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool positiveAllocation = tokenCount > 0;
        bool hardCapNotReached = totalTokensSoldandAllocated < hardCap;
        return withinPeriod && positiveAllocation && hardCapNotReached;
    }


    /** @dev Getter function to check the amount of allocated tokens
      * @param beneficiary address of the investor
      */
    function getAllocatedTokens(address beneficiary) public view returns(uint256 tokenCount) {
        require(beneficiary != address(0));
        return allocatedTokens[beneficiary];
    }

    function getSoldandAllocatedTokens(address _addr) public view returns (uint256) {
        require(_addr != address(0));
        uint256 totalTokenCount = getAllocatedTokens(_addr).add(getTokensSoldToEtherInvestor(_addr));
        return totalTokenCount;
    }

}

