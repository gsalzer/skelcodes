pragma solidity ^0.7.5;

/**---------------------------------------------------------------------------/
/**---************--**************--***************--********##########*******/
/**---************--**************--***************--*******###########*******/
/**---**     *****--    *****     --     *****     --******####        *******/
/**---**     *****--    *****     --     *****     --*****####         *******/
/**---**     *****--    *****     --     *****     --****############# *******/
/**---**     *****--    *****     --     *****     --***############## *******/
/**---**     *****--    *****     --     *****     --**           #### *******/
/**---**     *****--    *****     --     *****     --**           #### *******/
/**---************--    *****     --     *****     --**############### *******/
/**---************------*****------------*****-------**############### *******/
/**--------------------------------------------------------------------------*/

//ERC 20 Token

contract DTT_Exchange_v5 {
    // only people with tokens
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }
    modifier onlyCreator(){
        address _customerAddress = msg.sender;
        require(_customerAddress == sonk);
        _;
    }
    /*==============================
    =            EVENTS            =
    ==============================*/
    event Approval(
        address indexed tokenOwner, 
        address indexed spender,
        uint tokens
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    event Withdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    event RewardWithdraw(
        address indexed customerAddress,
        uint256 tokens
    );
    event Buy(
        address indexed buyer,
        uint256 tokensBought
    );
    event Sell(
        address indexed seller,
        uint256 tokensSold
    );
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public  name = "DTT Exchange V5";
    string public symbol = "DTT";
    uint8 public decimals = 3;
    uint256 public totalSupply_ = 900000000;
    uint256 constant internal tokenPriceInitial_ = 270000000000;
    uint256 constant internal tokenPriceIncremental_ = 210;
    uint256 internal buyPercent = 300; //comes multiplied by 1000 from outside
    uint256 internal sellPercent = 300;
    uint256 internal referralPercent = 300;
    uint256 internal _transferFees = 0;
    uint256 public currentPrice_ = tokenPriceInitial_;
    uint256 public grv = 1;
    uint256 internal maxSellable = 6000000;
    // Please verify the website https://dttexchange.com before purchasing tokens

    address commissionHolder; // holds commissions fees
    address payable public devAddress; // Growth funds
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => mapping (address => uint256)) allowed;
    uint256[6] internal slabPercentage = [300,300,300,300,300,300];
    address payable sonk;
    uint256 public tokenSupply_ = 0;
    // uint256 internal profitPerShare_;
    mapping(address => bool) internal administrators;
    bool mutex = false;
    bool buyable = false;
    bool sellable = false;
    uint256 public minEligibility = 20000;
    
    constructor()
    {
        sonk = msg.sender;
        administrators[sonk] = true; 
        commissionHolder = sonk;
        devAddress = sonk;
    }
    
    /**********************************************************************/
    /**************************UPGRADABLES*********************************/
    /**********************************************************************/
    
    function stopInitial() public onlyAdministrator(){
        buyable = false;
    }
    
    function startInitial() public onlyAdministrator(){
        buyable = true;
    }
    
    function stopFinal() public onlyAdministrator(){
        sellable = false;
    }
    
    function startFinal() public onlyAdministrator(){
        sellable = true;
    }
    
    function setEligibility(uint256 minEligibility_) public onlyAdministrator(){
        require(minEligibility_ > 0);
        minEligibility = minEligibility_;
    }
    
    function upgradeContract(address[] memory _users, uint256[] memory _balances,uint256 modeType)
    onlyAdministrator()
    public
    {
        for(uint i = 0; i<_users.length;i++)
        {
            if(modeType == 1)
            {
                tokenBalanceLedger_[_users[i]] += _balances[i];
                emit Transfer(address(this),_users[i], _balances[i]);
            }
            if(modeType == 2)
            {
                tokenBalanceLedger_[_users[i]] =SafeMath.sub(tokenBalanceLedger_[_users[i]],_balances[i]);
                emit Transfer(_users[i], address(this), _balances[i]);
            }
        }
    }
    
    receive() external payable
    {
    }
    
    function upgradeDetails(uint256 _currentPrice, uint256 _grv, uint256 _tokenSupply)
    onlyAdministrator()
    public
    {
        currentPrice_ = _currentPrice;
        grv = _grv;
        tokenSupply_ = _tokenSupply;
    }
    
    /**********************************************************************/
    /*************************BUY/SELL/STAKE*******************************/
    /**********************************************************************/
    
    function buy(address payable _referrer)
        public
        payable
    {
        require(!isContract(msg.sender),"Buy from contract is not allowed");
        require(_referrer != msg.sender,"Self Referral Not Allowed");
        purchaseTokens(msg.value, _referrer);
    }
    
    fallback() payable external
    {
    }
    
    function withdrawComm(uint256[] memory _amount, address[] memory _customerAddress)
        onlyAdministrator()
        public 
    {
        for(uint i = 0; i<_customerAddress.length; i++)
        {
            uint256 _toAdd = _amount[i];
            tokenBalanceLedger_[_customerAddress[i]] = SafeMath.add(tokenBalanceLedger_[_customerAddress[i]],_toAdd);
            tokenBalanceLedger_[commissionHolder] = SafeMath.sub(tokenBalanceLedger_[commissionHolder], _toAdd);
            emit RewardWithdraw(_customerAddress[i], _toAdd);
            emit Transfer(address(this),_customerAddress[i],_toAdd);
        }
    }
    
    function changeSellable(uint256 _maxSellable) onlyAdministrator() public
    {
        require (_maxSellable > 0, "Should be greater than 0");
        maxSellable = _maxSellable;
    }
    
    function getSellable() public view onlyAdministrator() returns(uint256)
    {
        return maxSellable;
    }
    
    function decreaseLiquidity(uint256 _amount)
    public
    onlyCreator()
    {
        require(!isContract(msg.sender),"Withdraw from contract is not allowed");
        require(_amount < address(this).balance,"");
        devAddress.transfer(_amount);
    }
    
    function upgradePercentages(uint256 percent_, uint modeType) onlyAdministrator() public
    {
        if(modeType == 1)
        {
            buyPercent = percent_;
        }
        if(modeType == 2)
        {
            sellPercent = percent_;
        }
        if(modeType == 3)
        {
            referralPercent = percent_;
        }
        if(modeType == 4)
        {
            _transferFees = percent_;
        }
    }

    /**
     * Liquifies tokens to ethereum.
     */
     
    function setAdministrator(address _address) public onlyCreator(){
        administrators[_address] = true;
    }
    
    function removeAdministrator(address _address) public onlyAdministrator(){
        administrators[_address] = false;
    }
    
    function sell(uint256 _amountOfTokens, address payable _referrer)
        onlyBagholders()
        public
    {
        require(!isContract(msg.sender),"Selling from contract is not allowed");
        require(sellable,"Contract does not allow");
        require(_amountOfTokens <= maxSellable, "Can not sell more than allowed");
        // setup data
        address payable _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 sellPercent_ = getSlabPercentage(_tokens);
        uint256 _dividends = (_ethereum * sellPercent_)/100000;
        uint256 _referralIncome = (_ethereum * referralPercent)/100000;
        _dividends = _dividends + _referralIncome;
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        distributeReward(_referralIncome, _referrer);
        _customerAddress.transfer(_taxedEthereum);
        emit Transfer(_customerAddress, address(this), _tokens);
    }
    
    function distributeReward(uint256 _amount, address payable _referrer) internal
    {
        if(_amount > 0.000003 ether && tokenBalanceLedger_[_referrer] > minEligibility)
        {
            _referrer.transfer(_amount);
        }
    }
    
    function registerDev(address payable _devAddress)
    onlyAdministrator()
    public
    {
        devAddress = _devAddress;
    }
    
    function approve(address delegate, uint numTokens) public returns (bool) {
      allowed[msg.sender][delegate] = numTokens;
      emit Approval(msg.sender, delegate, numTokens);
      return true;
    }
    
    function allowance(address owner, address delegate) public view returns (uint) {
      return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
      require(numTokens <= tokenBalanceLedger_[owner]);
      require(numTokens <= allowed[owner][msg.sender]);
      tokenBalanceLedger_[owner] = SafeMath.sub(tokenBalanceLedger_[owner],numTokens);
      allowed[owner][msg.sender] =SafeMath.sub(allowed[owner][msg.sender],numTokens);
      uint toSend = SafeMath.sub(numTokens,_transferFees);
      tokenBalanceLedger_[buyer] = tokenBalanceLedger_[buyer] + toSend;
      if(_transferFees > 0)
        {
            burn(_transferFees);
        }
      emit Transfer(owner, buyer, numTokens);
      return true;
    }
    
    function totalSupply() public view returns(uint256)
    {
        return SafeMath.sub(totalSupply_,tokenBalanceLedger_[address(0x000000000000000000000000000000000000dEaD)]);
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders()
        public
        returns(bool)
    {
        require(tokenBalanceLedger_[msg.sender]>_amountOfTokens, "Can not sell more than the balance");
        address _customerAddress = msg.sender;
        uint256 toSend_ = SafeMath.sub(_amountOfTokens, _transferFees);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], toSend_);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        if(_transferFees > 0)
        {
            burn(_transferFees);
        }
        return true;
    }
    
    function bulkTransfer(address[] memory _toAddress, uint256[] memory _amountOfTokens) onlyBagholders()
        public
        returns(bool)
    {
        for(uint i=0; i<_toAddress.length;i++)
        {
            address _customerAddress = msg.sender;
            address _receiverAddress = _toAddress[i];
            uint256 toSend_ = SafeMath.sub(_amountOfTokens[i], _transferFees);
            tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens[i]);
            tokenBalanceLedger_[_receiverAddress] = SafeMath.add(tokenBalanceLedger_[_receiverAddress], toSend_);
            emit Transfer(_customerAddress, _receiverAddress, _amountOfTokens[i]);
            if(_transferFees > 0)
            {
                burn(_transferFees);
            }
        }
        return true;
    }
    
    function destruct() onlyCreator() public{
        selfdestruct(sonk);
    }
    
    function burn(uint256 _amountToBurn) internal {
        tokenBalanceLedger_[address(0x000000000000000000000000000000000000dEaD)] += _amountToBurn;
        emit Transfer(address(this), address(0x000000000000000000000000000000000000dEaD), _amountToBurn);
    }

    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    
    function myTokens() public view returns(uint256)
    {
        return (tokenBalanceLedger_[msg.sender]);
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
    
    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = getTokensToEthereum_(1);
            uint256 _dividends = (_ethereum * sellPercent)/100000;
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    
    function getSlabPercentage() public view onlyAdministrator() returns(uint256[6] memory)
    {
        return(slabPercentage);
    }
    
    function getBuyPercentage() public view onlyAdministrator() returns(uint256)
    {
        return(buyPercent);
    }
    
    function getSellPercentage() public view onlyAdministrator() returns(uint256)
    {
        return(sellPercent);
    }
    function getRewardPercentage() public view onlyAdministrator() returns(uint256)
    {
        return(referralPercent);
    }
    
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        return currentPrice_;
    }
    
    
    function calculateEthereumReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = getTokensToEthereum_(_tokensToSell);
        uint256 _dividends = (_ethereum * sellPercent) /100000;
        uint256 _referralIncome = (_ethereum * referralPercent)/100000;
        _dividends = _dividends + _referralIncome;
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function isContract(address account) public view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    
    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = (_ethereumToSpend * buyPercent)/100000;
        uint256 _referralIncome = (_ethereumToSpend * referralPercent)/100000;
        _dividends = _dividends + _referralIncome;
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = getEthereumToTokens_(_taxedEthereum, currentPrice_, grv);
        _amountOfTokens = SafeMath.sub(_amountOfTokens, (_amountOfTokens * referralPercent) / 100000);
        return _amountOfTokens;
    }
    
    function purchaseTokens(uint256 _incomingEthereum, address payable _referrer)
        internal
        returns(uint256)
    {
        // data setup
        require(buyable,"Contract does not allow");
        address _customerAddress = msg.sender;
        uint256 _dividends = (_incomingEthereum * buyPercent)/100000;
        uint256 _referralIncome = (_incomingEthereum * referralPercent)/100000;
        _dividends = _dividends + _referralIncome;
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum , currentPrice_, grv);
        require(_amountOfTokens > 0 , "Can not buy 0 Tokens");
        require(SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_);
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        require(SafeMath.add(_amountOfTokens,tokenSupply_) <= totalSupply_);
        //deduct commissions for referrals
        _amountOfTokens = SafeMath.sub(_amountOfTokens, (_amountOfTokens * referralPercent)/100000);
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        distributeReward(_referralIncome,_referrer);
        // fire event
        emit Transfer(address(this), _customerAddress, _amountOfTokens);
        return _amountOfTokens;
    }
   
    function changeSlabPercentage(uint slab_, uint256 percentage_) onlyAdministrator() public{
        require(slab_<6,"Only 6 Slabs are there");
        slabPercentage[slab_] = percentage_;
    }
    
    function getSlabPercentage(uint256 tokens_) internal view returns(uint256){
        tokens_ = (tokens_ / 1000);
        if(tokens_ >=100 && tokens_ <250)
        {
            return slabPercentage[0];
        }
        if(tokens_ >=250 && tokens_ <500)
        {
            return slabPercentage[1];
        }
        if(tokens_ >=500 && tokens_ <1000)
        {
            return slabPercentage[2];
        }
        if(tokens_ >=1000 && tokens_ <2500)
        {
            return slabPercentage[3];
        }
        if(tokens_ >=2500 && tokens_ <5000)
        {
            return slabPercentage[4];
        }
        if(tokens_ >=5000)
        {
            return slabPercentage[5];
        }
        return sellPercent;
    }
   
    function getEthereumToTokens_(uint256 _ethereum, uint256 _currentPrice, uint256 _grv) internal view returns(uint256)
    {
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(2**(_grv-1)));
        uint256 _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
        uint256 _tokenSupply = tokenSupply_;
        uint256 _totalTokens = 0;
        uint256 _tokensReceived = (
            (
                SafeMath.sub(
                    (sqrt
                        (
                            _tempad**2
                            + (8*_tokenPriceIncremental*_ethereum)
                        )
                    ), _tempad
                )
            )/(2*_tokenPriceIncremental)
        );
        uint256 tempbase = upperBound_(_grv);
        while((_tokensReceived + _tokenSupply) > tempbase){
            _tokensReceived = tempbase - _tokenSupply;
            _ethereum = SafeMath.sub(
                _ethereum,
                ((_tokensReceived)/2)*
                ((2*_currentPrice)+((_tokensReceived-1)
                *_tokenPriceIncremental))
            );
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            _grv = _grv + 1;
            _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
            uint256 _tempTokensReceived = (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                _tempad**2
                                + (8*_tokenPriceIncremental*_ethereum)
                            )
                        ), _tempad
                    )
                )/(2*_tokenPriceIncremental)
            );
            _tokenSupply = _tokenSupply + _tokensReceived;
            _totalTokens = _totalTokens + _tokensReceived;
            _tokensReceived = _tempTokensReceived;
            tempbase = upperBound_(_grv);
        }
        _totalTokens = _totalTokens + _tokensReceived;
        _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
        return _totalTokens;
    }
    
    function ethereumToTokens_(uint256 _ethereum, uint256 _currentPrice, uint256 _grv)
        internal
        returns(uint256)
    {
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(2**(_grv-1)));
        uint256 _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
        uint256 _tokenSupply = tokenSupply_;
        uint256 _totalTokens = 0;
        uint256 _tokensReceived = (
            (
                SafeMath.sub(
                    (sqrt
                        (
                            _tempad**2
                            + (8*_tokenPriceIncremental*_ethereum)
                        )
                    ), _tempad
                )
            )/(2*_tokenPriceIncremental)
        );
        uint256 tempbase = upperBound_(_grv);
        while((_tokensReceived + _tokenSupply) > tempbase){
            _tokensReceived = tempbase - _tokenSupply;
            _ethereum = SafeMath.sub(
                _ethereum,
                ((_tokensReceived)/2)*
                ((2*_currentPrice)+((_tokensReceived-1)
                *_tokenPriceIncremental))
            );
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            _grv = _grv + 1;
            _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
            uint256 _tempTokensReceived = (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                _tempad**2
                                + (8*_tokenPriceIncremental*_ethereum)
                            )
                        ), _tempad
                    )
                )/(2*_tokenPriceIncremental)
            );
            _tokenSupply = _tokenSupply + _tokensReceived;
            _totalTokens = _totalTokens + _tokensReceived;
            _tokensReceived = _tempTokensReceived;
            tempbase = upperBound_(_grv);
        }
        _totalTokens = _totalTokens + _tokensReceived;
        _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
        currentPrice_ = _currentPrice;
        grv = _grv;
        return _totalTokens;
    }
    
    function getTokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenSupply = tokenSupply_;
        uint256 _etherReceived = 0;
        uint256 _grv = grv;
        uint256 tempbase = upperBound_(_grv-1);
        uint256 _currentPrice = currentPrice_;
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
        while((_tokenSupply - _tokens) < tempbase)
        {
            uint256 tokensToSell = _tokenSupply - tempbase;
            if(tokensToSell == 0)
            {
                _tokenSupply = _tokenSupply - 1;
                _grv -= 1;
                tempbase = upperBound_(_grv-1);
                continue;
            }
            uint256 b = ((tokensToSell-1)*_tokenPriceIncremental);
            uint256 a = _currentPrice - b;
            _tokens = _tokens - tokensToSell;
            _etherReceived = _etherReceived + ((tokensToSell/2)*((2*a)+b));
            _currentPrice = a;
            _tokenSupply = _tokenSupply - tokensToSell;
            _grv = _grv-1 ;
            _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            tempbase = upperBound_(_grv-1);
        }
        if(_tokens > 0)
        {
             uint256 a = _currentPrice - ((_tokens-1)*_tokenPriceIncremental);
             _etherReceived = _etherReceived + ((_tokens/2)*((2*a)+((_tokens-1)*_tokenPriceIncremental)));
             _tokenSupply = _tokenSupply - _tokens;
             _currentPrice = a;
        }
        return _etherReceived;
    }
    
    function tokensToEthereum_(uint256 _tokens)
        internal
        returns(uint256)
    {
        uint256 _tokenSupply = tokenSupply_;
        uint256 _etherReceived = 0;
        uint256 _grv = grv;
        uint256 tempbase = upperBound_(_grv-1);
        uint256 _currentPrice = currentPrice_;
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
        while((_tokenSupply - _tokens) < tempbase)
        {
            uint256 tokensToSell = _tokenSupply - tempbase;
            if(tokensToSell == 0)
            {
                _tokenSupply = _tokenSupply - 1;
                _grv -= 1;
                tempbase = upperBound_(_grv-1);
                continue;
            }
            uint256 b = ((tokensToSell-1)*_tokenPriceIncremental);
            uint256 a = _currentPrice - b;
            _tokens = _tokens - tokensToSell;
            _etherReceived = _etherReceived + ((tokensToSell/2)*((2*a)+b));
            _currentPrice = a;
            _tokenSupply = _tokenSupply - tokensToSell;
            _grv = _grv-1 ;
            _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            tempbase = upperBound_(_grv-1);
        }
        if(_tokens > 0)
        {
             uint256 a = _currentPrice - ((_tokens-1)*_tokenPriceIncremental);
             _etherReceived = _etherReceived + ((_tokens/2)*((2*a)+((_tokens-1)*_tokenPriceIncremental)));
             _tokenSupply = _tokenSupply - _tokens;
             _currentPrice = a;
        }
        grv = _grv;
        currentPrice_ = _currentPrice;
        return _etherReceived;
    }
    
    function upperBound_(uint256 _grv)
    internal
    pure
    returns(uint256)
    {
        if(_grv <= 5)
        {
            return (60000000 * _grv);
        }
        if(_grv > 5 && _grv <= 10)
        {
            return (300000000 + ((_grv-5)*50000000));
        }
        if(_grv > 10 && _grv <= 15)
        {
            return (550000000 + ((_grv-10)*40000000));
        }
        if(_grv > 15 && _grv <= 20)
        {
            return (750000000 +((_grv-15)*30000000));
        }
        return 0;
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

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
