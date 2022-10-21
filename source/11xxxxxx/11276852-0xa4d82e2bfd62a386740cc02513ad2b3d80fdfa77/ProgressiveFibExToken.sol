pragma solidity ^0.5.11;
//import "github.com/oraclize/ethereum-api/provableAPI.sol";
import "./provableAPI.sol";

import "./IERC20A.sol";
import "./SafeMath.sol";
import "./StableTokenInterface.sol";

contract ProgressiveFibExToken is usingProvable, IERC20A {
    using SafeMath for uint;
    
    string public constant name = "Progressive FibEx token";
    string public constant symbol = "ProF";
    uint8 public constant decimals = 6; 
    
    address payable private owner;
    address private stableAddress;
    address private escrowAddress;
    bool private isRising = false;
    uint private totalTokens; //текущее количество
    uint private oneETHToDollarPrice  = 46862;
    uint private boughtTokens;
    uint private upPercent = 0;
    bool private canTransfer = false;
    bool private canBuy = true;
    uint public maxEmission = 37000000000000;
    uint public provableTime = 3600;
    
    mapping (address => uint) private balances;
    mapping(bytes32=>bool) private pendingQueries;
    mapping(bytes32=>bool) private pendingQueriesNeed;
    
    event LogNewProvableQuery(string description, uint price);
    event LogPriceUpdated(string price);
    event OwnerTransfer(address _address, uint count, uint date);
    event BalancesSubbed(address contractAddress, address _address, uint count, uint date);
    event TokenConverted(
        address indexed _address,
        uint256 count,
        uint date
    );
    constructor () public payable {
        provable_setCustomGasPrice(42000000000);
        owner = msg.sender;
        rate(true, false);
    }
    
    modifier onlyOwner()
    {
        require(
            msg.sender == owner,
            "access_denied"
        );
        _;
    }
    
    modifier onlyStable()
    {
        require(
            msg.sender == stableAddress,
            "access_denied"
        );
        _;
    }
    
    modifier onlyEscrow()
    {
        require(
            msg.sender == escrowAddress,
            "access_denied"
        );
        _;
    }
    function emission(uint emissionCount, bool activateRaise) public onlyOwner {
        require(emissionCount > 0, "emission_not_null");
        emissionCount.add(1);
        if(totalTokens.add(emissionCount) > maxEmission) revert('tokens_count_max');
        totalTokens = totalTokens.add(emissionCount);
        balances[owner] = balances[owner].add(emissionCount);
        if(activateRaise == true) {
            isRising = true;
        }
    }
    
    function changeGasPrice(uint gasPrice) public onlyOwner {
        provable_setCustomGasPrice(gasPrice);
    }
    
    function setProvableTime(uint _time) public onlyOwner {
        provableTime = _time;
    }
    
    // Используем provable для получения цены
    function rate(bool immedeate, bool needToCall) private {
        if (provable_getPrice("URL") > address(this).balance) {
            emit LogNewProvableQuery("provable_fail", provable_getPrice("URL"));
        } else {
            emit LogNewProvableQuery("provable_success", provable_getPrice("URL"));
            bytes32 queryId;
            if(immedeate == false) {
                queryId = provable_query(provableTime, "URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price");
            } else {
                queryId = provable_query("URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price");
            }
            pendingQueries[queryId] = true;
            pendingQueriesNeed[queryId] = needToCall;
        }
    }
    
    function immedeateRate() public onlyOwner {
        rate(false, true);
    }
    
    function setRateNow() public onlyOwner {
        rate(true, false);
    }
    
    function  __callback(bytes32 myid,  string memory result) public {
        if (!pendingQueries[myid]) revert();
        if (msg.sender != provable_cbAddress()) revert();
        emit LogPriceUpdated(result);
        uint resultInt = parseInt(result, 2);
        if(resultInt != 0) oneETHToDollarPrice = resultInt;
        if (pendingQueriesNeed[myid] == true) {
            rate(false, true);
        }
        
        delete pendingQueries[myid];
        delete pendingQueriesNeed[myid];
   }
    
    function toogleCanBuy(bool _canBuy) public onlyOwner returns(bool) {
        canBuy = _canBuy;
        return canBuy;
    }
    
    function buy() payable public {
        if(!canBuy) revert('action_denied');
        uint sentWei = msg.value;
        if(sentWei == 0) revert('not_enough');
        uint oneTokenInWei = oneTokenCount();
        uint buyTokensCounts = (sentWei.mul(1000000).div(oneTokenInWei));
        uint buyTokensCountsNoAjio = buyTokensCounts.mul(10000).div(11500);
        uint ajioPayment =  buyTokensCounts.sub(buyTokensCountsNoAjio);
        uint resultTokens = (buyTokensCounts.sub(ajioPayment)).div(10000);
        if(resultTokens == 0) revert('not_enough_one');
        if(resultTokens > totalTokens) revert('not_enough_tokens_company');
        if(resultTokens > balances[owner]) revert('not_enough_tokens');
        balances[owner] = balances[owner].sub(resultTokens);
        balances[msg.sender] = balances[msg.sender].add(resultTokens);
        increaseSellsCount(resultTokens);
        emit Transfer(owner, msg.sender, resultTokens, now);
    }
    
    function oneTokenCount () public view returns(uint) {
        uint thousand = 1000;
        uint oneEther = 1 ether;
        uint crossrate = oneETHToDollarPrice.mul(1000000000000).div(thousand.add(upPercent));
        return (oneEther.mul(10000000).div(crossrate));
    }
    
    function oneDollarRate() public view returns(uint) {
        return oneETHToDollarPrice;
    }
    
    function currentRateCount() public view returns(uint) {
        uint thousand = 1000;
        return thousand.add(upPercent);
    }
    
    function setRaise(bool isRisingCurrent) public onlyOwner {
        isRising = isRisingCurrent;
    }
    
    function getRaise() public view returns(bool) {
		return isRising;
	}
    
    function increaseSellsCount(uint tokensNumber) private {
        if(isRising == false) return;
        boughtTokens = boughtTokens.add(tokensNumber);
        if(boughtTokens / 100000000 == 0) {
            return;
        }
        upPercent = boughtTokens.div(100000000);
    }
    
    function totalSupply() public view returns (uint256) {
        return totalTokens;
    }
    
    function takeComission(uint _value) private returns(uint){
        if(_value == 0) revert('no_sum');
        uint sumNoComission = _value.mul(100).div(101);
        uint comission = sumNoComission.div(100);
        uint resultComission = comission.mul(2);
        balances[owner] = balances[owner].add(resultComission);
        return resultComission;
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
    
    function setEscrowAddress(address _address) public onlyOwner {
        escrowAddress = _address;
    }
    
    function escrowSubstract(uint _value, address _addressTo) public onlyEscrow {
        if(escrowAddress == address(0)) revert('action_denied');
        if(_value == 0) revert('not_enough_tokens_payment');
        if(_value > balances[_addressTo]) revert('not_enough_tokens_payment');
        balances[_addressTo] = balances[_addressTo].sub(_value);
        emit BalancesSubbed(msg.sender, _addressTo, _value, now);
    }
    
    function escrowAdd(uint _value, address _addressTo) public onlyEscrow {
        if(escrowAddress == address(0)) revert('action_denied');
        if(_value == 0) revert('not_enough_tokens_payment');
        if(_value > totalTokens) revert('not_enough_tokens_payment');
        //если не владелец, не отправитель, не получатель - возвращаем
        balances[_addressTo] = balances[_addressTo].add(_value);
        if(_addressTo != owner) increaseSellsCount(_value);
        emit BalancesSubbed(msg.sender, _addressTo, _value, now );
    }
    
    function balanceOf(address _owner) view public returns (uint balance) {
        return balances[_owner];
    }
    
    function returnOwner() view public returns (address) {
        return owner;
    }
    
    function setStableAdress(address _address) public onlyOwner {
        stableAddress = _address;
    }
    
    function addConvertedTokens(address _address) public onlyStable {
        if(stableAddress == address(0)) revert('no_address_contract');
        if(_address == address(0)) revert('no_address_contract');
        StableTokenInterface stableT = StableTokenInterface(stableAddress);
        uint _value = stableT.getConvertValue(_address);
        if(_value == 0) revert('no_tokens');
        balances[_address] = balances[_address].add(_value);
        totalTokens = totalTokens.add(_value);
        increaseSellsCount(_value);
        stableT.conversionSuccessfull(_address);
        emit TokenConverted(
            _address,
            _value,
            now
        );  
    }
    
    function checkAccountEthereum() external view returns(uint) {
        return address(this).balance;
    }
    
    function sendEtherToOwner(uint amountInWei) external onlyOwner returns(uint) {
        if(address(this).balance < amountInWei) revert("not_enough");
        owner.transfer(amountInWei);
    }
    function addToBalance() external payable onlyOwner{
        
    }
}
