pragma solidity ^0.4.20;


library SafeMath {
    function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return (value*_quotient/1000000000000000000);
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract marks {
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    
    string public name                                      = "marks";
    string public symbol                                    = "ccmm";
    uint8 constant public decimals                          = 18;
    uint8 constant internal dividendFee_                    = 5;
    uint8 constant internal referralPer_                    = 20;
    uint8 constant internal developerFee_                   = 2;
    uint8 internal stakePer_                                = 1;
    uint256 constant internal tokenPriceInitial_            = 0.0001 ether;
    uint256 constant internal tokenPriceIncremental_        = 0.00001 ether;
    uint256 constant internal tokenPriceDecremental_        = 0.00001 ether;
    uint256 constant internal magnitude                     = 2**64;
    
    // Proof of stake (defaults at 1 token)
    uint256 public stakingRequirement                       = 1e18;
    
    // Ambassador program
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_        = 1 ether;
    uint256 constant internal ambassadorQuota_              = 1 ether;
    

    
    mapping(address => uint256) internal tbl;
    mapping(address => uint256) internal sbl;
    mapping(address => uint256) internal stakingTime_;
    mapping(address => uint256) internal referralBalance_;
    
    mapping(address => address) internal referralLevel1Address;
    mapping(address => address) internal referralLevel2Address;
    mapping(address => address) internal referralLevel3Address;
    mapping(address => address) internal referralLevel4Address;
    mapping(address => address) internal referralLevel5Address;
    mapping(address => address) internal referralLevel6Address;
    mapping(address => address) internal referralLevel7Address;
    mapping(address => address) internal referralLevel8Address;
    mapping(address => address) internal referralLevel9Address;
    mapping(address => address) internal referralLevel10Address;
    
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_                           = 0;
    uint256 internal developerBalance                       = 0;
    uint256 internal profitPerShare_;
    
    // administrator list (see above on what they can do)
    mapping(bytes32 => bool) public administrators;
    bool public onlyAmbassadors = false;
    
    /*=================================
    =            MODIFIERS            =
    =================================*/
    
    // Only people with tokens
    modifier onlybelievers () {
        require(myTokens() > 0);
        _;
    }
    
    // Only people with profits
    modifier onlyhodler() {
        require(myDividends(true) > 0);
        _;
    }
    
    // Only admin
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[keccak256(_customerAddress)]);
        _;
    }
    
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                // is the customer in the ambassador list?
                ambassadors_[_customerAddress] == true &&
                // does the customer purchase exceed the max ambassador quota?
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_
            );
            // updated the accumulated quota    
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
            _;
        } else {
            // in case the ether count drops low, the ambassador phase won't reinitiate
            onlyAmbassadors = false;
            _;    
        }
    }
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );
    
    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );
    
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    function marks() public {
        // add administrators here
        administrators[0x2b1ec49a01a5b87a226360f74b9dcf488a076b16a1d2400ce659bf0a311514c] = true;
        ambassadors_[0x0000000000000000000000000000000000000000] = true;
    }
     
    /**
     * Converts all incoming Ethereum to tokens for the caller, and passes down the referral address (if any)
     */
    function buy(address _referredBy) public payable returns(uint256) {
        purchaseTokens(msg.value, _referredBy);
    }
    
    function() payable public {
        purchaseTokens(msg.value, 0x0);
    }
    
    /**
     * Converts all of caller's dividends to tokens.
     */
    function reinvest() onlyhodler() public {
        // fetch dividends
        uint256 _dividends                  = myDividends(false); // retrieve ref. bonus later in the code
        // pay out the dividends virtually
        address _customerAddress            = msg.sender;
        payoutsTo_[_customerAddress]        +=  (int256) (_dividends * magnitude);
        // retrieve ref. bonus
        _dividends                          += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress]  = 0;
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens                     = purchaseTokens(_dividends, 0x0);
        // fire event
        onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
    /**
     * Alias of sell() and withdraw().
     */
    function exit() public {
        // get token count for caller & sell them all
        address _customerAddress            = msg.sender;
        uint256 _tokens                     = tbl[_customerAddress];
        if(_tokens > 0) sell(_tokens);
        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw() onlyhodler() public {
        // setup data
        address _customerAddress            = msg.sender;
        uint256 _dividends                  = myDividends(false); // get ref. bonus later in the code
        // update dividend tracker
        payoutsTo_[_customerAddress]        +=  (int256) (_dividends * magnitude);
        // add ref. bonus
        _dividends                          += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress]  = 0;
        // delivery service
        _customerAddress.transfer(_dividends);
        // fire event
        onWithdraw(_customerAddress, _dividends);
    }
    
    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens) onlybelievers () public {
        address _customerAddress            = msg.sender;
        require(_amountOfTokens <= tbl[_customerAddress]);
        uint256 _tokens                     = _amountOfTokens;
        uint256 _ethereum                   = tokensToEthereum_(_tokens);
        // uint256 _dividends                  = SafeMath.div(_ethereum, dividendFee_);
        uint256 _dividends                  = SafeMath.percent(_ethereum,dividendFee_,100,18);
        uint256 _taxedEthereum              = SafeMath.sub(_ethereum, _dividends);
        // burn the sold tokens
        tokenSupply_                        = SafeMath.sub(tokenSupply_, _tokens);
        tbl[_customerAddress] = SafeMath.sub(tbl[_customerAddress], _tokens);
        // update dividends tracker
        int256 _updatedPayouts              = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress]        -= _updatedPayouts;       
        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_                 = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        // fire event
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    
    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's a 10% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens) onlybelievers () public returns(bool) {
        address _customerAddress            = msg.sender;
        // make sure we have the requested tokens
        require(!onlyAmbassadors && _amountOfTokens <= tbl[_customerAddress]);
        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) withdraw();
        // liquify 10% of the tokens that are transfered
        // these are dispersed to shareholders
        // uint256 _tokenFee                   = SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _tokenFee                   = SafeMath.percent(_amountOfTokens,dividendFee_,100,18);
        uint256 _taxedTokens                = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends                  = tokensToEthereum_(_tokenFee);
        // burn the fee tokens
        tokenSupply_                        = SafeMath.sub(tokenSupply_, _tokenFee);
        // exchange tokens
        tbl[_customerAddress] = SafeMath.sub(tbl[_customerAddress], _amountOfTokens);
        tbl[_toAddress]     = SafeMath.add(tbl[_toAddress], _taxedTokens);
        // update dividend trackers
        payoutsTo_[_customerAddress]        -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress]              += (int256) (profitPerShare_ * _taxedTokens);
        // disperse dividends among holders
        profitPerShare_                     = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        // fire event
        Transfer(_customerAddress, _toAddress, _taxedTokens);
        return true;
    }
    
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    /**
     * administrator can manually disable the ambassador phase.
     */
    function disableInitialStage() onlyAdministrator() public {
        onlyAmbassadors                     = false;
    }
    
    function changeStakePercent(uint8 stakePercent) onlyAdministrator() public {
        stakePer_                           = stakePercent;
    }
    
    function setAdministrator(bytes32 _identifier, bool _status) onlyAdministrator() public {
        administrators[_identifier]         = _status;
    }
    
    function setStakingRequirement(uint256 _amountOfTokens) onlyAdministrator() public {
        stakingRequirement                  = _amountOfTokens;
    }
    
    function setName(string _name) onlyAdministrator() public {
        name                                = _name;
    }
    
    function setSymbol(string _symbol) onlyAdministrator() public {
        symbol                              = _symbol;
    }
    
    function drain() external onlyAdministrator {
        address _adminAddress = msg.sender;
        _adminAddress.transfer(this.balance);
    }
    
    function drainDeveloperFees() external onlyAdministrator {
        address _adminAddress = msg.sender;
        _adminAddress.transfer(developerBalance);
    }
    
    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */
    function totalEthereumBalance() public view returns(uint) {
        return this.balance;
    }
    /**
     * Retrieve the total developer fee balance.
     */
    function totalDeveloperBalance() public view returns(uint) {
        return developerBalance;
    }
    /**
     * Retrieve the total token supply.
     */
    function totalSupply() public view returns(uint256) {
        return tokenSupply_;
    }
    
    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens() public view returns(uint256) {
        address _customerAddress            = msg.sender;
        return balanceOf(_customerAddress);
    }
    
    /**
     * Retrieve the dividends owned by the caller.
       */ 
    function myDividends(bool _includeReferralBonus) public view returns(uint256) {
        address _customerAddress            = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress) view public returns(uint256) {
        return tbl[_customerAddress];
    }
    
    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress) view public returns(uint256) {
        return (uint256) ((int256)(profitPerShare_ * (tbl[_customerAddress] + sbl[_customerAddress])) - payoutsTo_[_customerAddress]) / magnitude;
    }
    
    /**
     * Return the buy price of 1 individual token.
     */
    function sellPrice() public view returns(uint256) {
        if(tokenSupply_ == 0){
            return tokenPriceInitial_       - tokenPriceDecremental_;
        } else {
            uint256 _ethereum               = tokensToEthereum_(1e18);
            // uint256 _dividends              = SafeMath.div(_ethereum, dividendFee_  );
            uint256 _dividends              = SafeMath.percent(_ethereum,dividendFee_,100,18);
            uint256 _taxedEthereum          = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    
    /**
     * Return the sell price of 1 individual token.
     */
    function buyPrice() public view returns(uint256) {
        if(tokenSupply_ == 0){
            return tokenPriceInitial_       + tokenPriceIncremental_;
        } else {
            uint256 _ethereum               = tokensToEthereum_(1e18);
            // uint256 _dividends              = SafeMath.div(_ethereum, dividendFee_  );
            uint256 untotalDeduct           = developerFee_ + referralPer_ + dividendFee_;
            uint256 totalDeduct             = SafeMath.percent(_ethereum,untotalDeduct,100,18);
            // uint256 _dividends              = SafeMath.percent(_ethereum,dividendFee_,100,18);
            uint256 _taxedEthereum          = SafeMath.add(_ethereum, totalDeduct);
            return _taxedEthereum;
        }
    }
   
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns(uint256) {
        // uint256 _dividends                  = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint256 untotalDeduct               = developerFee_ + referralPer_ + dividendFee_;
        uint256 totalDeduct                 = SafeMath.percent(_ethereumToSpend,untotalDeduct,100,18);
        // uint256 _dividends                  = SafeMath.percent(_ethereumToSpend,dividendFee_,100,18);
        uint256 _taxedEthereum              = SafeMath.sub(_ethereumToSpend, totalDeduct);
        uint256 _amountOfTokens             = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }
   
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns(uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum                   = tokensToEthereum_(_tokensToSell);
        // uint256 _dividends                  = SafeMath.div(_ethereum, dividendFee_);
        uint256 _dividends                  = SafeMath.percent(_ethereum,dividendFee_,100,18);
        uint256 _taxedEthereum              = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    function stakeTokens(uint256 _amountOfTokens) onlybelievers () public returns(bool){
        address _customerAddress            = msg.sender;
        // make sure we have the requested tokens
        require(!onlyAmbassadors && _amountOfTokens <= tbl[_customerAddress]);
        uint256 _amountOfTokensWith1Token   = SafeMath.sub(_amountOfTokens, 1e18);
        stakingTime_[_customerAddress]      = now;
        sbl[_customerAddress] = SafeMath.add(sbl[_customerAddress], _amountOfTokensWith1Token);
        tbl[_customerAddress] = SafeMath.sub(tbl[_customerAddress], _amountOfTokensWith1Token);
    }
    
    // Add daily ROI
    function stakeTokensBalance(address _customerAddress) public view returns(uint256){
        uint256 timediff                    = SafeMath.sub(now, stakingTime_[_customerAddress]);
        uint256 dayscount                   = SafeMath.div(timediff, 86400); //86400 Sec for 1 Day
        uint256 roiPercent                  = SafeMath.mul(dayscount, stakePer_);
        uint256 roiTokens                   = SafeMath.percent(sbl[_customerAddress],roiPercent,100,18);
        uint256 finalBalance                = SafeMath.add(sbl[_customerAddress],roiTokens);
        return finalBalance;
    }
    
    function stakeTokensTime(address _customerAddress) public view returns(uint256){
        return stakingTime_[_customerAddress];
    }
    
    function releaseStake() onlybelievers () public returns(bool){
        address _customerAddress            = msg.sender;
        // make sure we have the requested tokens
        require(!onlyAmbassadors && stakingTime_[_customerAddress] > 0);
        uint256 _amountOfTokens             = sbl[_customerAddress];
        uint256 timediff                    = SafeMath.sub(now, stakingTime_[_customerAddress]);
        uint256 dayscount                   = SafeMath.div(timediff, 86400);
        uint256 roiPercent                  = SafeMath.mul(dayscount, stakePer_);
        uint256 roiTokens                   = SafeMath.percent(_amountOfTokens,roiPercent,100,18);
        uint256 finalBalance                = SafeMath.add(_amountOfTokens,roiTokens);
        
        // add tokens to the pool
        tokenSupply_                        = SafeMath.add(tokenSupply_, roiTokens);
        // transfer tokens back
        tbl[_customerAddress] = SafeMath.add(tbl[_customerAddress], finalBalance);
        sbl[_customerAddress] = 0;
        stakingTime_[_customerAddress]      = 0;
        
    }
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    
    uint256 developerFee;
    uint256 incETH;
    address _refAddress; 
    uint256 _referralBonus;
    
    uint256 bonusLv1;
    uint256 bonusLv2;
    uint256 bonusLv3;
    uint256 bonusLv4;
    uint256 bonusLv5;
    uint256 bonusLv6;
    uint256 bonusLv7;
    uint256 bonusLv8;
    uint256 bonusLv9;
    uint256 bonusLv10;
    
    address chkLv2;
    address chkLv3;
    address chkLv4;
    address chkLv5;
    address chkLv6;
    address chkLv7;
    address chkLv8;
    address chkLv9;
    address chkLv10;
    
    /*********** NEED TO CHANGE BELOW LINE ***************/
    /** need to change public to internal */
    /** need to check referralPer_ in ref. bonus */

    function getref1(address _customerAddress) public view returns(address) {
        address lv1 = referralLevel1Address[_customerAddress];
        return lv1;
    }
    
    function getref2(address _customerAddress) public view returns(address) {
        address lv2 = referralLevel2Address[_customerAddress];
        return lv2;
    }
    
    function getref3(address _customerAddress) public view returns(address) {
        address lv3 = referralLevel3Address[_customerAddress];
        return lv3;
    }
    
    function getref4(address _customerAddress) public view returns(address) {
        address lv4 = referralLevel4Address[_customerAddress];
        return lv4;
    }
    
    function getref5(address _customerAddress) public view returns(address) {
        address lv5 = referralLevel5Address[_customerAddress];
        return lv5;
    }
    
    function getref6(address _customerAddress) public view returns(address) {
        address lv6 = referralLevel6Address[_customerAddress];
        return lv6;
    }
    
    function getref7(address _customerAddress) public view returns(address) {
        address lv7 = referralLevel7Address[_customerAddress];
        return lv7;
    }
    
    function getref8(address _customerAddress) public view returns(address) {
        address lv8 = referralLevel8Address[_customerAddress];
        return lv8;
    }
    
    function getref9(address _customerAddress) public view returns(address) {
        address lv9 = referralLevel9Address[_customerAddress];
        return lv9;
    }
    
    function getref10(address _customerAddress) public view returns(address) {
        address lv10 = referralLevel10Address[_customerAddress];
        return lv10;
    }
    
    function distributeRefBonus(uint256 _incomingEthereum, address _referredBy, address _sender) internal {
        address _customerAddress        = _sender;
        uint256 remainingRefBonus       = _incomingEthereum;
        _referralBonus                  = _incomingEthereum;
        
        bonusLv1                        = SafeMath.percent(_referralBonus,30,100,18);
        bonusLv2                        = SafeMath.percent(_referralBonus,20,100,18);
        bonusLv3                        = SafeMath.percent(_referralBonus,10,100,18);
        bonusLv4                        = SafeMath.percent(_referralBonus,5,100,18);
        bonusLv5                        = SafeMath.percent(_referralBonus,3,100,18);
        bonusLv6                        = SafeMath.percent(_referralBonus,2,100,18);
        bonusLv7                        = SafeMath.percent(_referralBonus,2,100,18);
        bonusLv8                        = SafeMath.percent(_referralBonus,2,100,18);
        bonusLv9                        = SafeMath.percent(_referralBonus,1,100,18);
        bonusLv10                       = SafeMath.percent(_referralBonus,1,100,18);
        
        // Level 1
        referralLevel1Address[_customerAddress]                     = _referredBy;
        referralBalance_[referralLevel1Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel1Address[_customerAddress]], bonusLv1);
        remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv1);
        
        chkLv2                          = referralLevel1Address[_referredBy];
        chkLv3                          = referralLevel2Address[_referredBy];
        chkLv4                          = referralLevel3Address[_referredBy];
        chkLv5                          = referralLevel4Address[_referredBy];
        chkLv6                          = referralLevel5Address[_referredBy];
        chkLv7                          = referralLevel6Address[_referredBy];
        chkLv8                          = referralLevel7Address[_referredBy];
        chkLv9                          = referralLevel8Address[_referredBy];
        chkLv10                         = referralLevel9Address[_referredBy];
        
        // Level 2
        if(chkLv2 != 0x0000000000000000000000000000000000000000) {
            referralLevel2Address[_customerAddress]                     = referralLevel1Address[_referredBy];
            referralBalance_[referralLevel2Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel2Address[_customerAddress]], bonusLv2);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv2);
        }
        
        // Level 3
        if(chkLv3 != 0x0000000000000000000000000000000000000000) {
            referralLevel3Address[_customerAddress]                     = referralLevel2Address[_referredBy];
            referralBalance_[referralLevel3Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel3Address[_customerAddress]], bonusLv3);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv3);
        }
        
        // Level 4
        if(chkLv4 != 0x0000000000000000000000000000000000000000) {
            referralLevel4Address[_customerAddress]                     = referralLevel3Address[_referredBy];
            referralBalance_[referralLevel4Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel4Address[_customerAddress]], bonusLv4);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv4);
        }
        
        // Level 5
        if(chkLv5 != 0x0000000000000000000000000000000000000000) {
            referralLevel5Address[_customerAddress]                     = referralLevel4Address[_referredBy];
            referralBalance_[referralLevel5Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel5Address[_customerAddress]], bonusLv5);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv5);
        }
        
        // Level 6
        if(chkLv6 != 0x0000000000000000000000000000000000000000) {
            referralLevel6Address[_customerAddress]                     = referralLevel5Address[_referredBy];
            referralBalance_[referralLevel6Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel6Address[_customerAddress]], bonusLv6);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv6);
        }
        
        // Level 7
        if(chkLv7 != 0x0000000000000000000000000000000000000000) {
            referralLevel7Address[_customerAddress]                     = referralLevel6Address[_referredBy];
            referralBalance_[referralLevel7Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel7Address[_customerAddress]], bonusLv7);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv7);
        }
        
        // Level 8
        if(chkLv8 != 0x0000000000000000000000000000000000000000) {
            referralLevel8Address[_customerAddress]                     = referralLevel7Address[_referredBy];
            referralBalance_[referralLevel8Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel8Address[_customerAddress]], bonusLv8);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv8);
        }
        
        // Level 9
        if(chkLv9 != 0x0000000000000000000000000000000000000000) {
            referralLevel9Address[_customerAddress]                     = referralLevel8Address[_referredBy];
            referralBalance_[referralLevel9Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel9Address[_customerAddress]], bonusLv9);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv9);
        }
        
        // Level 10
        if(chkLv10 != 0x0000000000000000000000000000000000000000) {
            referralLevel10Address[_customerAddress]                    = referralLevel9Address[_referredBy];
            referralBalance_[referralLevel10Address[_customerAddress]]  = SafeMath.add(referralBalance_[referralLevel10Address[_customerAddress]], bonusLv10);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv10);
        }
        
        developerBalance                    = SafeMath.add(developerBalance, remainingRefBonus);
    }

    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) antiEarlyWhale(_incomingEthereum) internal returns(uint256) {
        // data setup
        address _customerAddress            = msg.sender;
        incETH                              = _incomingEthereum;
        // Developer Fees 2%
        developerFee                        = SafeMath.percent(incETH,developerFee_,100,18);
        developerBalance                    = SafeMath.add(developerBalance, developerFee);
        
        _referralBonus                      = SafeMath.percent(incETH,referralPer_,100,18);
        
        uint256 _dividends                  = SafeMath.percent(incETH,dividendFee_,100,18);
        
        uint256 untotalDeduct               = developerFee_ + referralPer_ + dividendFee_;
        uint256 totalDeduct                 = SafeMath.percent(incETH,untotalDeduct,100,18);
        
        uint256 _taxedEthereum              = SafeMath.sub(incETH, totalDeduct);
        uint256 _amountOfTokens             = ethereumToTokens_(_taxedEthereum);
        uint256 _fee                        = _dividends * magnitude;
        
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        // is the user referred by a link?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&
            // no cheating!
            _referredBy != _customerAddress &&
            tbl[_referredBy] >= stakingRequirement
        ){
            // wealth redistribution
            distributeRefBonus(_referralBonus,_referredBy,_customerAddress);
        } else {
            // no ref purchase
            // send referral bonus back to admin
            developerBalance                = SafeMath.add(developerBalance, _referralBonus);
        }
        // we can't give people infinite ethereum
        if(tokenSupply_ > 0){
            // add tokens to the pool
            tokenSupply_                    = SafeMath.add(tokenSupply_, _amountOfTokens);
            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_                 += (_dividends * magnitude / (tokenSupply_));
            // calculate the amount of tokens the customer receives over his purchase 
            _fee                            = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        } else {
            // add tokens to the pool
            tokenSupply_                    = _amountOfTokens;
        }
        // update circulating supply & the ledger address for the customer
        tbl[_customerAddress] = SafeMath.add(tbl[_customerAddress], _amountOfTokens);
        int256 _updatedPayouts              = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress]        += _updatedPayouts;
        // fire event
        onTokenPurchase(_customerAddress, incETH, _amountOfTokens, _referredBy);
        return _amountOfTokens;
    }

    /**
     * Calculate Token price based on an amount of incoming ethereum
     * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function ethereumToTokens_(uint256 _ethereum) internal view returns(uint256) {
        uint256 _tokenPriceInitial          = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived             = 
         (
            (
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(tokenSupply_)
        ;

        return _tokensReceived;
    }
    
    /**
     * Calculate token sell value.
     */
     function tokensToEthereum_(uint256 _tokens) internal view returns(uint256) {
        uint256 tokens_                     = (_tokens + 2e18);
        uint256 _tokenSupply                = (tokenSupply_ + 2e18);
        uint256 _etherReceived              =
        (
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceDecremental_ * (_tokenSupply/2e18))
                        )-tokenPriceDecremental_
                    )*(tokens_ - 2e18)
                ),(tokenPriceDecremental_*((tokens_**2-tokens_)/2e18))/2
            )
        /2e18);
        return _etherReceived;
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
