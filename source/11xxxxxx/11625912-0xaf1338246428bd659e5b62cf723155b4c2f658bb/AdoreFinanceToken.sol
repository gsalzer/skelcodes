pragma solidity ^0.7.5;

contract AdoreFinanceToken {
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
    /*==============================
    =            EVENTS            =
    ==============================*/

    event Reward(
       address indexed to,
       uint256 rewardAmount,
       uint256 level
    );
    
    event RewardWithdraw(
       address indexed from,
       uint256 rewardAmount
    );
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    event Approval(
        address indexed tokenOwner, 
        address indexed spender,
        uint tokens
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
    string public name = "Adore Finance Token";
    string public symbol = "XFA";
    uint8 constant public decimals = 0;
    uint256 public totalSupply_ = 2000000;
    uint256 constant internal tokenPriceInitial_ = 0.00012 ether;
    uint256 constant internal tokenPriceIncremental_ = 25000000;
    uint256 public currentPrice_ = tokenPriceInitial_ + tokenPriceIncremental_;
    uint256 public base = 1;
    uint public percent = 500;
    uint public referralPercent = 1000;
    uint public sellPercent = 1500;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal rewardBalanceLedger_;
    mapping(address => mapping (address => uint256)) allowed;
    address commissionHolder;
    uint256 internal tokenSupply_ = 0;
    mapping(address => bool) internal administrators;
    mapping(address => address) public genTree;
    mapping(address => uint256) public level1Holding_;
    address payable internal creator;
    address internal management; //for management funds
    address internal poolFund;
    uint8[] percent_ = [7,2,1];
    uint8[] adminPercent_ = [37,37,16,10];
    address dev1;
    address dev2;
    address dev3;
    address dev4;
    bool buyable = false;
    bool sellable = false;
   
    constructor()
    {
        creator = msg.sender;
        administrators[creator] = true;
    }
    
    function upgradeContract(address[] memory _users, uint256[] memory _balances, uint256[] memory _rewardBalances, address[] memory _refers, uint modeType)
    onlyAdministrator()
    public
    {
        if(modeType == 1)
        {
            for(uint i = 0; i<_users.length;i++)
            {
                 genTree[_users[i]] = _refers[i];
                if(_balances[i] > 0)
                {
                    tokenBalanceLedger_[_users[i]] += _balances[i];
                    rewardBalanceLedger_[_users[i]] += _rewardBalances[i];
                    tokenSupply_ += _balances[i];
                    emit Transfer(address(this),_users[i],_balances[i]);
                }
            }
        }
        if(modeType == 2)
        {
            for(uint i = 0; i<_users.length;i++)
            {
                genTree[_users[i]] = _refers[i];
                if(_balances[i] > 0)
                {
                    tokenBalanceLedger_[_users[i]] -= _balances[i];
                    rewardBalanceLedger_[_users[i]] -= _rewardBalances[i];
                    tokenSupply_ -= _balances[i];
                    emit Transfer(_users[i],address(this),_balances[i]);
                }
            }
        }
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
      tokenBalanceLedger_[buyer] = SafeMath.add(tokenBalanceLedger_[buyer],numTokens);
      emit Transfer(owner, buyer, numTokens);
      return true;
    }
    
    function upgradeDetails(uint256 _currentPrice, uint256 _grv, uint256 _commFunds)
    onlyAdministrator()
    public
    {
        currentPrice_ = _currentPrice;
        base = _grv;
        rewardBalanceLedger_[management] = _commFunds;
    }
    
    function upgradePercentages(uint256 _percent, uint modeType) onlyAdministrator() public
    {
        if(modeType == 1)
        {
            referralPercent = _percent;
        }
        if(modeType == 2)
        {
            sellPercent = _percent;
        }
        if(modeType == 3)
        {
            percent = _percent;
        }
    }
    
    function setAdministrator(address _address) public onlyAdministrator(){
        administrators[_address] = true;
    }
    
    function removeAdministrator(address _address) public onlyAdministrator(){
        administrators[_address] = false;
    }
    
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
   
    function withdrawRewards(address payable _customerAddress, uint256 _amount) onlyAdministrator() public
    {
        require(rewardBalanceLedger_[_customerAddress]>=_amount && _amount > 3000000000000000);
        rewardBalanceLedger_[commissionHolder] += 3000000000000000;
        rewardBalanceLedger_[_customerAddress] -= _amount;
        emit RewardWithdraw(_customerAddress,_amount);
        _amount = SafeMath.sub(_amount, 3000000000000000);
        _customerAddress.transfer(_amount);
    }

    function setDevs(address _dev1, address _dev2, address _dev3, address _dev4) onlyAdministrator() public{
        dev1 = _dev1;
        dev2 = _dev2;
        dev3 = _dev3;
        dev4 = _dev4;
    }
    function distributeCommission() onlyAdministrator() public returns(bool)
    {
        require(rewardBalanceLedger_[management]>100000000000000);
        rewardBalanceLedger_[dev1] += (rewardBalanceLedger_[management]*3600)/10000;
        rewardBalanceLedger_[dev2] += (rewardBalanceLedger_[management]*3600)/10000;
        rewardBalanceLedger_[dev3] += (rewardBalanceLedger_[management]*1500)/10000;
        rewardBalanceLedger_[dev4] += (rewardBalanceLedger_[management]*1300)/10000;
        rewardBalanceLedger_[management] = 0;
        return true;
    }
    
    function withdrawRewards(uint256 _amount) onlyAdministrator() public
    {
        address payable _customerAddress = msg.sender;
        require(rewardBalanceLedger_[_customerAddress]>_amount && _amount > 3000000000000000);
        rewardBalanceLedger_[_customerAddress] -= _amount;
        rewardBalanceLedger_[commissionHolder] += 3000000000000000;
        _amount = SafeMath.sub(_amount, 3000000000000000);
        _customerAddress.transfer(_amount);
    }
   
    function distributeRewards(uint256 _amountToDistribute, address _idToDistribute)
    internal
    {
        uint256 _tempAmountToDistribute = _amountToDistribute;
        for(uint i=0; i<3; i++)
        {
            address referrer = genTree[_idToDistribute];
            if(referrer != address(0x0) && level1Holding_[referrer] > i && i>0)
            {
                rewardBalanceLedger_[referrer] += (_amountToDistribute*percent_[i])/10;
                _idToDistribute = referrer;
                emit Reward(referrer,(_amountToDistribute*percent_[i])/10,i);
                _tempAmountToDistribute -= (_amountToDistribute*percent_[i])/10;
            }
            else if(i == 0)
            {
                 rewardBalanceLedger_[referrer] += (_amountToDistribute*percent_[i])/10;
                _idToDistribute = referrer;
                emit Reward(referrer,(_amountToDistribute*percent_[i])/10,i);
                _tempAmountToDistribute -= (_amountToDistribute*percent_[i])/10;
            }
            else
            {
                
            }
        }
        rewardBalanceLedger_[commissionHolder] += _tempAmountToDistribute;
    }
   
    function buy(address _referredBy)
        public
        payable
    {
        require(!isContract(msg.sender),"Buy from contract is not allowed");
        require(_referredBy != msg.sender,"Self Referral Not Allowed");
        if(genTree[msg.sender]!=_referredBy)
            level1Holding_[_referredBy] +=1;
        genTree[msg.sender] = _referredBy;
        purchaseTokens(msg.value);
    }
   
    receive() external payable
    {
        require(msg.value > currentPrice_, "Very Low Amount");
        purchaseTokens(msg.value);
    }
    
    fallback() external payable
    {
        require(msg.value > currentPrice_, "Very Low Amount");
        purchaseTokens(msg.value);
    }
   
    bool mutex = true;
     
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
        // setup data
        require(!isContract(msg.sender),"Selling from contract is not allowed");
        require (mutex == true);
        address payable _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens,true);
        uint256 _dividends = _ethereum * (sellPercent)/10000;
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        rewardBalanceLedger_[management] += _dividends;
        rewardBalanceLedger_[commissionHolder] += 3000000000000000;
        _dividends = _dividends + 3000000000000000;
        _ethereum = SafeMath.sub(_ethereum,_dividends);
        _customerAddress.transfer(_ethereum);
        emit Transfer(_customerAddress, address(this), _tokens);
    }
   
    function rewardOf(address _toCheck)
        public view
        returns(uint256)
    {
        return rewardBalanceLedger_[_toCheck];    
    }
   
    function transfer(address _toAddress, uint256 _amountOfTokens)
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }
   
    function destruct() onlyAdministrator() public{
        selfdestruct(creator);
    }
   
    function setName(string memory _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
   
    function setSymbol(string memory _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

    function setupWallets(address _commissionHolder, address payable _management, address _poolFunds)
    onlyAdministrator()
    public
    {
        commissionHolder = _commissionHolder;
        management = _management;
        poolFund = _poolFunds;
    }
    
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
   
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return totalSupply_;
    }
   
    function tokenSupply()
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
     * Return the sell price of 1 individual token.
     */
    function buyPrice()
        public
        view
        returns(uint256)
    {
        return currentPrice_;
    }
   
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
   
    function purchaseTokens(uint256 _incomingEthereum)
        internal
        returns(uint256)
    {
        // data setup
        require(buyable,"Contract does not allow");
        uint256 _totalDividends = 0;
        uint256 _dividends = _incomingEthereum * referralPercent/10000;
        _totalDividends += _dividends;
        address _customerAddress = msg.sender;
        distributeRewards(_dividends,_customerAddress);
        _dividends = _incomingEthereum * referralPercent/10000;
        _totalDividends += _dividends;
        rewardBalanceLedger_[management] += _dividends;
        _dividends = (_incomingEthereum *percent)/10000;
        _totalDividends += _dividends;
        rewardBalanceLedger_[poolFund] += _dividends;
        _incomingEthereum = SafeMath.sub(_incomingEthereum, _totalDividends);
        
        uint256 _amountOfTokens = ethereumToTokens_(_incomingEthereum , currentPrice_, base, true);
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        require(SafeMath.add(_amountOfTokens,tokenSupply_) < (totalSupply_));
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        // fire event
        emit Transfer(address(this), _customerAddress, _amountOfTokens);
        return _amountOfTokens;
    }
   
    function ethereumToTokens_(uint256 _ethereum, uint256 _currentPrice, uint256 _grv, bool _buy)
        internal
        returns(uint256)
    {
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(3**(_grv-1)));
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
            _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
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
        if(_buy == true)
        {
            currentPrice_ = _currentPrice;
            base = _grv;
        }
        return _totalTokens;
    }
    
    function getEthereumToTokens_(uint256 _ethereum)
    public view returns(uint256)
    {
        uint256 _grv = base;
        uint256 _currentPrice = currentPrice_;
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(3**(_grv-1)));
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
            _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
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
   
    function upperBound_(uint256 _grv)
    internal
    pure
    returns(uint256)
    {
        uint256 topBase = 0;
        for(uint i = 1;i<=_grv;i++)
        {
            topBase +=200000-((_grv-i)*10000);
        }
        return topBase;
    }
   
     function tokensToEthereum_(uint256 _tokens, bool _sell)
        internal
        returns(uint256)
    {
        uint256 _tokenSupply = tokenSupply_;
        uint256 _etherReceived = 0;
        uint256 _grv = base;
        uint256 tempbase = upperBound_(_grv-1);
        uint256 _currentPrice = currentPrice_;
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
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
            _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
            tempbase = upperBound_(_grv-1);
        }
        if(_tokens > 0)
        {
             uint256 a = _currentPrice - ((_tokens-1)*_tokenPriceIncremental);
             _etherReceived = _etherReceived + ((_tokens/2)*((2*a)+((_tokens-1)*_tokenPriceIncremental)));
             _tokenSupply = _tokenSupply - _tokens;
             _currentPrice = a;
        }
       
        if(_sell == true)
        {
            base = _grv;
            currentPrice_ = _currentPrice;
        }
        return _etherReceived;
    }
    
    function getTokensToEthereum_(uint256 _tokens)
        public view returns(uint256)
    {
        uint256 _tokenSupply = tokenSupply_;
        uint256 _etherReceived = 0;
        uint256 _grv = base;
        uint256 tempbase = upperBound_(_grv-1);
        uint256 _currentPrice = currentPrice_;
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
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
            _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
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
   
   
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
