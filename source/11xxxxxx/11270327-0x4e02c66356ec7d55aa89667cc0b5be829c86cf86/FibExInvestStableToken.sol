pragma solidity ^0.5.11;

import "./SafeMath.sol";
import "./IERC20A.sol";
import "./ProgressiveTokenInterface.sol";

contract FibExInvestStableToken is IERC20A {
    using SafeMath for uint;
    
    string public constant name = "FibEx Invest Stable token";
    string public constant symbol = "FIns";
    uint8 public constant decimals = 6;
    
    address payable public owner;
    address public progressiveFibExAdress;
    uint public totalTokens; //текущее количество
    uint public oneETHToDollarPrice; // текущий курс к доллару(Основная часть) в gwei(10^-9)
    uint public boughtTokens;
    bool private canTransfer = false;
    uint public ajioPercent = 75;
    
    mapping (address => mapping (address => uint)) allowed;
    mapping (address => uint) balances;
    mapping (address => uint) pendingConversions;
    mapping(uint => uint) deals;
    
    event Convert(uint countPro, uint countSta, uint initialTokenCt, uint comission,  uint tokensCt, address _address);
    event ConversionReturn(address _address, uint count, uint comission, uint date);
    event ConversionSuccess(address _address, uint count, uint date);
    event AgioPayment(address _address, uint count, uint date);
    event OwnerTransfer(address _address, uint count, uint date);
    event DealActivation(address _address, uint dealId, uint totalEth, uint tokensCounts, uint ethTokenPayment, uint ajioPayment);
    
    //Конструктор выполняется один раз при публикации контракта
    constructor () public payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner()
    {
        require(
            msg.sender == owner,
            "access_denied"
        );
        _;
    }
    
    modifier onlyProgressive()
    {
        require(
            msg.sender == progressiveFibExAdress,
            "access_denied"
        );
        _;
    }
    
    function setAjioToFull() public onlyOwner {
        ajioPercent = 150;
    }
    
    function setAjioToHalf() public onlyOwner {
        ajioPercent = 75;
    }
    
    function setAjioInUsd(uint dealId, uint usdPrice) public onlyOwner {
        deals[dealId] = usdPrice;
    }
    
	function getAjioInUsd(uint dealId) public view returns(uint) {
        return deals[dealId];
    }
	
    function activateDeal(uint dealId) payable public {
        if(deals[dealId] == 0) revert('no_deal');
        uint sentWei = msg.value;
        if(sentWei == 0) revert('not_enough');
        getRate();
        uint oneUsdInWei = oneTokenCount();
        uint ajioPayment = deals[dealId].mul(oneUsdInWei).mul(100);
        if(ajioPayment > sentWei)  revert('not_enough');
        uint tokensEth = sentWei.sub(ajioPayment);
        uint resultTokens = (tokensEth.mul(1000000).div(oneUsdInWei)).div(10000);
        if(resultTokens > balances[owner]) revert('not_enough_tokens_company');
        balances[msg.sender] = balances[msg.sender].add(resultTokens);
        balances[owner] = balances[owner].sub(resultTokens);
        emit DealActivation(msg.sender, dealId, sentWei, resultTokens, tokensEth, ajioPayment);
    }
    
    function setAdress(address contractItem) public onlyOwner {
        progressiveFibExAdress = contractItem;
    }
    
    function getRate() public {
        if(progressiveFibExAdress == address(0)) revert('no_address_rate');
        ProgressiveTokenInterface pro = ProgressiveTokenInterface(progressiveFibExAdress);
        oneETHToDollarPrice = pro.oneDollarRate();
    }
    
    function oneDollarRate() public view returns(uint) {
        if(progressiveFibExAdress == address(0)) revert('no_address_rate');
        if(oneETHToDollarPrice == 0) revert('rate_not_set');
        return oneETHToDollarPrice;
    }
    
    function convertToProgressive(uint value) public {
        if(progressiveFibExAdress == address(0)) revert('no_address_rate');
        if(value == 0) revert('no_tokens');
        if(value > balances[msg.sender]) revert('not_enough_tokens');
        ProgressiveTokenInterface pro = ProgressiveTokenInterface(progressiveFibExAdress);
        getRate();
        uint oneTokenStable = oneTokenCount();
        uint comission = takeComission(value);
        uint valueNoWithoutComission = value.sub(comission);
        uint oneTokenProgressive = pro.oneTokenCount();
        uint resultTokens = valueNoWithoutComission.mul(1000).div(oneTokenProgressive.mul(1000).div(oneTokenStable));
        emit Convert(valueNoWithoutComission.mul(1000), (oneTokenProgressive.mul(1000).div(oneTokenStable)), comission, valueNoWithoutComission, resultTokens, msg.sender);
        if(resultTokens == 0) revert('conversion_result');
        balances[msg.sender] = balances[msg.sender].sub(value);
        pendingConversions[msg.sender] = resultTokens;
        pro.addConvertedTokens(msg.sender);
        emit Convert(oneTokenProgressive, oneTokenStable, comission, valueNoWithoutComission, resultTokens, msg.sender);
    }
    
    function payReferal(address _address, uint count) public onlyOwner {
        if(count == 0) revert('no_tokens');
        if(_address == address(0)) revert('no_address');
        if(count > totalTokens) revert('not_enough_tokens_company');
        if(count > balances[owner]) revert('not_enough_tokens_payment');
        balances[owner] = balances[owner].sub(count);
        balances[_address] = balances[_address].add(count);
        emit OwnerTransfer(_address, count, now);
    }
    
    function takeComission(uint _value) private returns(uint){
        if(_value == 0) revert('no_sum');
        uint comission = _value.div(100);
        balances[owner] = balances[owner].add(comission);
        return comission;
    }
    
    function getConvertValue(address _address) public view returns(uint) {
        if(pendingConversions[_address] == 0) return 0;
        return pendingConversions[_address];
    }
    
    function returnComission(uint _value) private returns(uint) {
        uint originalValue = _value.mul(100).div(99);
        uint comission = originalValue.div(100);
        balances[owner] = balances[owner].sub(comission);
        return comission;
    }
    
    function returnPendingTokens() public  {
        if(pendingConversions[msg.sender] == 0) revert('action_incorrect');
        uint comission = returnComission(pendingConversions[msg.sender]);
        uint resultCount = pendingConversions[msg.sender].add(comission);
        balances[msg.sender] = balances[msg.sender].add(resultCount);
        delete pendingConversions[msg.sender];
        emit ConversionReturn(msg.sender, resultCount, comission, now);

    }
    
    function conversionSuccessfull(address _address) public onlyProgressive returns(bool) {
        if(pendingConversions[_address] == 0) revert('action_incorrect');
        delete pendingConversions[_address];
        emit ConversionSuccess(_address, pendingConversions[_address], now);
        return true;
    }
    
    //Эмиссия - проверяем является ли тот кто запрашивает, владельцем контракта
    // Проверяем сумму
    // проверяем переполнение
    // в случае успеха добавляем токены владельцу контракта и в общее количество
    function emission(uint emissionCount) external onlyOwner {
        require(emissionCount > 0, "emission_not_null");
        
        totalTokens = totalTokens.add(emissionCount);
        balances[owner] = balances[owner].add(emissionCount);
    }
    
    function buy() payable public {
        uint sentWei = msg.value;
        if(sentWei == 0) revert('not_enough');
        getRate();
		uint tenThousand = 10000;
        uint oneTokenInWei = oneTokenCount();
        uint buyTokensCounts = (sentWei.mul(1000000).div(oneTokenInWei));
        uint buyTokensCountsNoAjio = buyTokensCounts.mul(tenThousand).div(tenThousand.add(ajioPercent.mul(10)));
        uint ajioPayment =  buyTokensCounts.sub(buyTokensCountsNoAjio);
        uint resultTokens = (buyTokensCounts.sub(ajioPayment)).div(10000);
        if(resultTokens > totalTokens) revert('not_enough_tokens_company');
        if(resultTokens > balances[owner]) revert('not_enough_tokens_company');
        balances[msg.sender] = balances[msg.sender].add(resultTokens);
        balances[owner] = balances[owner].sub(resultTokens);
        emit Transfer(owner, msg.sender, resultTokens, now);
    }
    
    function toggleCanTransfer(bool enable) public onlyOwner {
         canTransfer = enable;
    }
    
    function transferEnabled() public view returns(bool) {
        return canTransfer;
    }
    
    function transfer(address _to, uint _value) public returns(bool) {
        if(!canTransfer) revert('action_denied');
        if(_to == msg.sender) revert('address_match');
        if(_value == 0) revert('no_tokens');
        if(_value > totalTokens) revert('not_enough_tokens_company');
        if(balances[msg.sender] < _value) revert('not_enough_tokens');
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, now);
        return true;
    }
    
    function oneTokenCount () public view returns(uint) {
        uint oneEther = 1 ether;
        return (oneEther.mul(10000000).div(oneETHToDollarPrice.mul(1000000000)));
    }
    
    //Показываем общее количество токенов
    function totalSupply() external view returns (uint256) {
        return totalTokens;
    }
    
    function balanceOf(address _owner) view public returns (uint balance) {
        return balances[_owner];
    }
    
    function checkAccountEthereum() external view returns(uint) {
        return address(this).balance;
    }
    
    function sendEtherToOwner(uint amountInWei) external onlyOwner returns(uint) {
        if(address(this).balance < amountInWei) revert("not_enough");
        owner.transfer(amountInWei);
    }
    
    function returnOwner() view public returns (address) {
        return owner;
    }
    
    function addToBalance() external payable onlyOwner{
        
    }
    
}
