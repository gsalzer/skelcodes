pragma solidity ^0.5.8;
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./ReentrancyGuard.sol";
contract WeFairPlayInvestment is ReentrancyGuard{
    using SafeMath for uint;
    using IterableMapping for IterableMapping.itmap;
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }
    modifier onlyOwner()
    {
        require(owner == msg.sender);
        _;
    }
    modifier onlyAdministrator(){
        require(owner == msg.sender || administrators[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }
    modifier onlyOperators(){
        require(mapOperatorStocks_.contains(uint(msg.sender))
            && mapOperatorStocks_.data[uint(msg.sender)].value > 0);
        _;
    }
    modifier notEarlyWhale(){
        require(!onlyAmbassadors);
        _;
    }
    modifier notEndStage(){
        require(!isEndStage);
        _;
    }
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        if(!onlyAmbassadors) {
            _;
            return;
        }
        address _customerAddress = msg.sender;
          if( onlyAmbassadors && (totalEthereumBalance() < ambassadorQuota_ )){
            require(
                ambassadors_[_customerAddress] == true &&
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_);
                ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
            _;
        } else {
            onlyAmbassadors = false;
            _;
        }

    }
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
    string public name = "WeFairPlayCoin";
    string public symbol = "WFP";
    uint8 constant public decimals = 18;
    uint8 constant internal operatorFee_ = 10;
    uint8 constant internal dividendFee_ = 10;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    uint256 public stakingRequirement = 100e18;
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 1 ether;
    uint256 constant internal ambassadorQuota_ = 10 ether;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    mapping(bytes32 => bool) public administrators;
    bool public onlyAmbassadors = true;
    IterableMapping.itmap mapOperatorRewards_;
    IterableMapping.itmap mapOperatorStocks_;
    uint totalOperatorRewards;
    uint256 constant public totalStocks_ = 10000;
    uint lastActiveTime;
    uint constant internal ENTER_END_DURATION = 2 * 4 weeks;//10 minutes;//2 * 4 weeks;
    bool public isEndStage;
    uint public enterEndTime;
    uint constant internal END_STAGE_DURATION = 4 weeks;//10 minutes;//4 weeks;
    address owner;
    constructor()
    public
    {
        owner = msg.sender;
         administrators[0x6e87e5c3130679f898089256718f36b117cb685debd8d2511298b3f0dabadf1e] = true;
        ambassadors_[0x1Fd11576EAbe588115aA47E52904C3221E4c0a95] = true;
        ambassadors_[0x1DC93b1bE8b97959f5B07d6113A909F9C89D3361] = true;
        ambassadors_[0x135de610Bd907e9B6aB3d93753d6E59De6ef886B] = true;
        ambassadors_[0x5f5B2BB60EBDa86C9efc9a4cA01a7756554c2Fe5] = true;
        ambassadors_[0x89EE32611CcFa44044cc1F0d0ECC53E53Aa3C634] = true;
        ambassadors_[0x16B0e5F320Cd30028caFf791aC08dF830B52e61d] = true;
        ambassadors_[0xA9d47178067568A5C84c0849A7e1b47139DA6a7c] = true;
        ambassadors_[0x0d7e1a43e666714A1B7B8F4e5eD9Ac86597078A0] = true;
        ambassadors_[0xc33F6Ca865D8Ec8fE00037f64B8dbe6cBD751555] = true;
        ambassadors_[0x324bC683445fa86CFc85b49c1eD4d2bdDc6409aE] = true;
        mapOperatorStocks_.add_or_insert(uint(owner),totalStocks_);
    }
    function ambassadorLeftLimit()
    view
    public
    returns(uint)
    {
        if(ambassadors_[msg.sender]) {
            return ambassadorMaxPurchase_.sub(ambassadorAccumulatedQuota_[msg.sender]);
        }
        return 0;
    }
    function isAmbassador()
    view
    public
    returns(bool)
    {
        return ambassadors_[msg.sender];
    }
    function buy(address _referredBy)
    public
    payable
    {
        purchaseTokens(msg.value, _referredBy);
    }
    function()
    payable
    external
    {
        purchaseTokens(msg.value, address(0x0));
    }
    function reinvest()
    onlyStronghands()
    public
    {
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(_dividends, address(0x0));
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }
    function exit()
    public
    {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
        withdraw();
    }
    function withdraw()
    nonReentrant()
    onlyStronghands()
    notEarlyWhale()
    public
    {
        address payable _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        emit onWithdraw(_customerAddress, _dividends);
    }
    function sell(uint256 _amountOfTokens)
    notEarlyWhale()
    onlyBagholders()
    public
    {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        uint256 operatorDividends = SafeMath.div(_dividends, operatorFee_);
        sendOperatorRewards_(operatorDividends);
        _dividends = _dividends - operatorDividends;
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;
        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        lastActiveTime = now;
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    function _transfer(address _from, address _toAddress, uint _amountOfTokens)
    notEarlyWhale()
    notEndStage()
    internal
    {
        address _customerAddress = _from;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        if(myDividends(true) > 0) withdraw();
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);
        uint256 operatorDividends = SafeMath.div(_dividends, operatorFee_);
        sendOperatorRewards_(operatorDividends);
        _dividends = _dividends - operatorDividends;
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        lastActiveTime = now;
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);
    }
    function transfer(address _toAddress, uint256 _amountOfTokens)
    onlyBagholders()
    public
    returns(bool)
    {
        _transfer(msg.sender, _toAddress, _amountOfTokens);
        return true;
    }
    function isAdministrator()
    view
    public
    returns(bool)
    {
        return (owner == msg.sender || administrators[keccak256(abi.encodePacked(msg.sender))]);
    }
    function disableInitialStage()
    onlyOwner()
    public
    {
        onlyAmbassadors = false;
    }
    function setAdministrator(bytes32 _identifier, bool _status)
    onlyAdministrator()
    public
    {
        administrators[_identifier] = _status;
    }
    function setOwner(address payable newOwner) onlyOwner public
    {
        owner = newOwner;
    }
    function canEnterEndStage() view public returns(bool)
    {
        return (!isEndStage && lastActiveTime > 0 && now - lastActiveTime > ENTER_END_DURATION);
    }
    function enterEndStage() onlyOwner public
    {
        require(!isEndStage);
        require(lastActiveTime > 0 && now - lastActiveTime > ENTER_END_DURATION);
        isEndStage = true;
        enterEndTime = now;
    }
    function restEndTime() view public returns(int)
    {
        if(isEndStage && enterEndTime > 0)
        {
            uint endTimestamp = enterEndTime.add(END_STAGE_DURATION);
            if(now < endTimestamp)
            {
                return int(endTimestamp.sub(now));
            }
            else
            {
                return 0;
            }
        }
        return -1;
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function kill() onlyOwner public
    {
        require(isEndStage && enterEndTime > 0 && now - enterEndTime > END_STAGE_DURATION);
        selfdestruct(toPayable(owner));
    }
    function setStakingRequirement(uint256 _amountOfTokens)
    onlyAdministrator()
    public
    {
        stakingRequirement = _amountOfTokens;
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
        return tokenSupply_;
    }
    function myTokens()
    public
    view
    returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    function myDividends(bool _includeReferralBonus)
    public
    view
    returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
    function balanceOf(address _customerAddress)
    view
    public
    returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
    function dividendsOf(address _customerAddress)
    view
    public
    returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }
    function sellPrice()
    public
    view
    returns(uint256)
    {
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    function buyPrice()
    public
    view
    returns(uint256)
    {
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = _ethereum.div( dividendFee_  );
            uint256 _taxedEthereum = _ethereum.add( _dividends);
            return _taxedEthereum;
        }
    }
    function calculateTokensReceived(uint256 _ethereumToSpend)
    public
    view
    returns(uint256)
    {
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }
    function calculateEthereumReceived(uint256 _tokensToSell)
    public
    view
    returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
    antiEarlyWhale(_incomingEthereum)
    notEndStage()
    internal
    returns(uint256)
    {
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        sendOperatorRewards_(SafeMath.div(_undividedDividends, operatorFee_));
        _undividedDividends = _undividedDividends - SafeMath.div(_undividedDividends, operatorFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        if(
            _referredBy != address(0x0000000000000000000000000000000000000000) &&
            _referredBy != _customerAddress &&
        tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        if(tokenSupply_ > 0){
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        } else {
            tokenSupply_ = _amountOfTokens;
        }
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        lastActiveTime = now;
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
        return _amountOfTokens;
    }
    function ethereumToTokens_(uint256 _ethereum)
    internal
    view
    returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
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
    function tokensToEthereum_(uint256 _tokens)
    internal
    view
    returns(uint256)
    {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
        SafeMath.sub(
            (
            (
            (
            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
            )-tokenPriceIncremental_
            )*(tokens_ - 1e18)
            ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
        )
        /1e18);
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
    function sendOperatorRewards_(uint256 _ethereum)
    internal
    {
        uint restRewards = _ethereum;
        for(uint i = mapOperatorStocks_.iterate_start(); mapOperatorStocks_.iterate_valid(i) && restRewards>0; i = mapOperatorStocks_.iterate_next(i))
        {
            (uint addrOperator,uint stocks) = mapOperatorStocks_.iterate_get(i);
            if(stocks == 0)
            {
                continue;
            }
            uint256 rewards = _ethereum.mul(stocks).div(totalStocks_);
            if(rewards > restRewards)
            {
                rewards = restRewards;
            }
            restRewards = restRewards.sub(rewards);
            mapOperatorRewards_.add_or_insert(addrOperator,rewards);
            totalOperatorRewards = totalOperatorRewards.add(rewards);
        }
    }
    function getOperatorStocks_()
    view
    public
    returns(uint)
    {
        return mapOperatorStocks_.data[uint(msg.sender)].value;
    }
    function getOperatorRewards_()
    view
    public
    returns(uint)
    {
        return mapOperatorRewards_.data[uint(msg.sender)].value;
    }
    function withDrawRewards_()
    nonReentrant()
    notEarlyWhale()
    onlyOperators()
    public
    {
        uint player = uint(msg.sender);
        require(mapOperatorRewards_.contains(player));
        uint totalRewards = mapOperatorRewards_.data[player].value;
        require(totalRewards>0 && totalRewards <= totalOperatorRewards && totalRewards <= address(this).balance);
        mapOperatorRewards_.sub(player,totalRewards);
        totalOperatorRewards = totalOperatorRewards.sub(totalRewards);
        msg.sender.transfer(totalRewards);
    }
    function transferStocks_(address receiver,uint amountStock)
    nonReentrant()
    onlyOperators()
    notEarlyWhale()
    notEndStage()
    public
    {
        uint sender = uint(msg.sender);
        uint restStocks = uint(mapOperatorStocks_.data[sender].value);
        require(amountStock <= restStocks);
        mapOperatorStocks_.add_or_insert(uint(receiver),amountStock);
        mapOperatorStocks_.sub(sender,amountStock);
        if(mapOperatorStocks_.data[sender].value == 0)
        {
            uint totalRewards = mapOperatorRewards_.data[sender].value;
            mapOperatorStocks_.remove(sender);
            mapOperatorRewards_.remove(sender);
            if(totalRewards > 0)
            {
                if(totalRewards > totalOperatorRewards)
                {
                    totalRewards = totalOperatorRewards;
                }
                totalOperatorRewards = totalOperatorRewards.sub(totalRewards);
                address(sender).transfer(totalRewards);
            }
        }
    }
}

