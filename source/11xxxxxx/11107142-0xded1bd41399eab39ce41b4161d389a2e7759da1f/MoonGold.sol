pragma solidity ^0.5.10;

import "./ERC20Interface.sol";
import "./SafeMath.sol";


contract MoonGold {

    using SafeMath for uint256;

    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlybelievers () {
        require(myTokens() > 0, "Not Believer");
        _;
    }
    
    // only people with profits
    modifier onlyhodler() {
        require(myDividends(true) > 0, "Not Holder");
        _;
    }
    
    
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingMoonday,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 moondayEarned
    );
    
    event onReinvestment(
        address indexed customerAddress,
        uint256 moondayReinvested,
        uint256 tokensMinted
    );
    
    event onWithdraw(
        address indexed customerAddress,
        uint256 moondayWithdrawn
    );
    
    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Moon Gold";
    string public symbol = "MOONGold";
    uint256 constant public decimals = 18;
    uint256 constant internal dividendFee_ = 6;
    uint256 constant internal MANAGER_FEE = 3;
    uint256 constant internal PARTNER_FEE = 1;
	uint256 constant internal DEV_FEE = 1;
    uint256 constant internal CAPITAL_FEE = 10;

    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    
    // proof of stake (defaults at 1 token)
    uint256 public stakingRequirement = 1 ether;
    
    
    ERC20Interface MoondayToken;
    
   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;

    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;


    address payable public managerAddress;
    address payable public devAddress;
	address payable public partnerAddress;
    address payable public partnerAddress2;
    address payable public moondayCapitalAddress;
    

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor(
        address payable _managerAddress, 
        address payable _partnerAddress, 
        address payable _partnerAddress2, 
        address payable _devAddress,
        address payable _moondayCapitalAddress,
        address _MoondayToken
        ) public {
        managerAddress = _managerAddress;
        partnerAddress = _partnerAddress;
        partnerAddress2 = _partnerAddress2;
		devAddress = _devAddress;
        moondayCapitalAddress = _moondayCapitalAddress;
        MoondayToken = ERC20Interface(_MoondayToken);
    }
    
     
    /**
     * Converts all incoming Moonday to MoonGold for the caller, and passes down the referral address (if any)
     */
    function buy(uint256 _amount, address _referredBy)
        public
        returns(uint256)
    {
        uint256 received = _amount.mul(99).div(100);

		MoondayToken.transferFrom(msg.sender, address(this), _amount);
        purchaseTokens(received, _referredBy);
    }
    
    
    /**
     * Converts all of caller's dividends to tokens.
     */
    function reinvest()
        onlyhodler()
        public
    {
        // fetch dividends
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code
        
        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, address(0));
        
        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
    /**
     * Alias of sell() and withdraw().
     */
    function exit()
        public
    {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
        
        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
        onlyhodler()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code
        
        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // delivery service

        MoondayToken.transfer(_customerAddress, _dividends);
        
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    
    /**
     * Liquifies tokens to Moonday.
     */
    function sell(uint256 _amountOfTokens)
        onlybelievers ()
        public
    {
      
        address _customerAddress = msg.sender;
       
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress], "Invalid amount to sell");
        uint256 _tokens = _amountOfTokens;
        uint256 _moonday = tokensToMoonday_(_tokens);
        uint256 _dividends = _moonday.mul(dividendFee_).div(100);
        uint256 _taxedMoonday = _moonday.sub(_dividends);
        
        // burn the sold tokens
        tokenSupply_ = tokenSupply_.sub(_tokens);
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress].sub(_tokens);
        
        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedMoonday * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;       
        
        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = profitPerShare_.add((_dividends * magnitude) / tokenSupply_);
        }
        
        // fire event
        emit onTokenSell(_customerAddress, _tokens, _taxedMoonday);
    }
    
    
    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's a 6% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlybelievers ()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        
        // make sure we have the requested tokens
     
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress], "Invalid Balance");
        
        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) withdraw();
        
        // liquify 6% of the tokens that are transfered
        // these are dispersed to shareholders
        uint256 _tokenFee = _amountOfTokens.mul(dividendFee_).div(100);
        uint256 _taxedTokens = _amountOfTokens.sub(_tokenFee);
        uint256 _dividends = tokensToMoonday_(_tokenFee);
  
        // burn the fee tokens
        tokenSupply_ = tokenSupply_.sub(_tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress].sub(_amountOfTokens);
        tokenBalanceLedger_[_toAddress] = tokenBalanceLedger_[_toAddress].add(_taxedTokens);
        
        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
        
        // disperse dividends among holders
        profitPerShare_ = profitPerShare_.add((_dividends * magnitude) / tokenSupply_);
        
        // fire event
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);
        
        // ERC20
        return true;
       
    }
    
    
    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Moonday stored in the contract
     * Example: totalMoondayBalance()
     */
    function totalMoondayBalance()
        public
        view
        returns(uint256)
    {
        return MoondayToken.balanceOf(address(this));
    }
    
    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }
    
    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
    /**
     * Retrieve the dividends owned by the caller.
       */ 
    function myDividends(bool _includeReferralBonus)
        public 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }
    
    /**
     * Return the buy price of 1 individual token.
     */
    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
       
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _moonday = tokensToMoonday_(1e18);
            uint256 _dividends = _moonday.mul(dividendFee_).div(100);
            uint256 _taxedMoonday = _moonday.sub(_dividends);
            return _taxedMoonday;
        }
    }
    
    /**
     * Return the sell price of 1 individual token.
     */
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _moonday = tokensToMoonday_(1e18);
            uint256 _dividends = _moonday.mul(dividendFee_).div(100);
            uint256 _taxedMoonday = _moonday.add(_dividends);
            return _taxedMoonday;
        }
    }
    
   
    function calculateTokensReceived(uint256 _moondayToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = _moondayToSpend.mul(dividendFee_).div(100);
        uint256 _taxedMoonday = _moondayToSpend.sub(_dividends);
        uint256 _amountOfTokens = moondayToTokens_(_taxedMoonday);
        
        return _amountOfTokens;
    }
    
   
    function calculateMoondayReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_, "Invalid amount to sell");
        uint256 _moonday = tokensToMoonday_(_tokensToSell);
        uint256 _dividends = _moonday.mul(dividendFee_).div(100);
        uint256 _taxedMoonday = _moonday.sub(_dividends);
        return _taxedMoonday;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint256 _incomingMoonday, address _referredBy)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = _incomingMoonday.mul(dividendFee_).div(100);
        
        uint256 _referralBonus = _undividedDividends.div(3);

        uint256 totalBonus = _referralBonus
            .add(_undividedDividends.mul(MANAGER_FEE).div(100))
            .add(_undividedDividends.mul(PARTNER_FEE).div(100))
            .add(_undividedDividends.mul(PARTNER_FEE).div(100))
            .add(_undividedDividends.mul(DEV_FEE).div(100))
            .add(_undividedDividends.mul(CAPITAL_FEE).div(100));

        MoondayToken.transfer(managerAddress, _undividedDividends.mul(MANAGER_FEE).div(100));
		MoondayToken.transfer(partnerAddress, _undividedDividends.mul(PARTNER_FEE).div(100));
        MoondayToken.transfer(partnerAddress2, _undividedDividends.mul(PARTNER_FEE).div(100));
		MoondayToken.transfer(devAddress, _undividedDividends.mul(DEV_FEE).div(100));
		MoondayToken.transfer(moondayCapitalAddress, _undividedDividends.mul(CAPITAL_FEE).div(100));

        uint256 _dividends = _undividedDividends.sub(totalBonus);
        uint256 _taxedMoonday = _incomingMoonday.sub(_undividedDividends);
        uint256 _amountOfTokens = moondayToTokens_(_taxedMoonday);
        uint256 _fee = _dividends * magnitude;
 
      
        require(_amountOfTokens > 0 && (_amountOfTokens.add(tokenSupply_) > tokenSupply_), "Invalid amount");
        
        // is the user referred by a link?
        if(
            // is this a referred purchase?
            _referredBy != address(0) &&

            // no cheating!
            _referredBy != _customerAddress &&
            
        
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
            // wealth redistribution
            referralBalance_[_referredBy] = referralBalance_[_referredBy].add(_referralBonus); 
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = _dividends.add(_referralBonus); 
            _fee = _dividends * magnitude;
        }
        
        // we can't give people infinite Moonday
        if(tokenSupply_ > 0){
            
            // add tokens to the pool
            tokenSupply_ = tokenSupply_.add(_amountOfTokens); 
 
            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            
            // calculate the amount of tokens the customer receives over his purchase 
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }
        
        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress].add(_amountOfTokens);
        
        
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
        // fire event
        emit onTokenPurchase(_customerAddress, _incomingMoonday, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }

    /**
     * Calculate Token price based on an amount of incoming Moonday
     * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function moondayToTokens_(uint256 _moonday)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = 
         (
            (
                // underflow attempts BTFO
                (sqrt
                    (
                        (_tokenPriceInitial**2)
                        +
                        (2*(tokenPriceIncremental_ * 1e18)*(_moonday * 1e18))
                        +
                        (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                        +
                        (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                    )
                ).sub(_tokenPriceInitial)
            )/(tokenPriceIncremental_)
        )-(tokenSupply_)
        ;
  
        return _tokensReceived;
    }
    
    /**
     * Calculate token sell value.
          */
     function tokensToMoonday_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _moondayReceived =
        (
            // underflow attempts BTFO
            (
                (
                    (
                        tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                    )-tokenPriceIncremental_
                )*(tokens_ - 1e18)
            ).sub((tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2)
        /1e18);
        return _moondayReceived;
    }
    
    
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

