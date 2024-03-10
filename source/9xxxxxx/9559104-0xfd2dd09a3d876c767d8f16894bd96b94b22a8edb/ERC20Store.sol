pragma solidity ^0.4.24;

import "IERC20ImplUpgradeable.sol";
import "Authorization.sol";
import "SafeMath.sol";

contract ERC20Store is Authorization {
    using SafeMath for uint256;

    struct Balance {
        uint256 timestamp;
        uint256 value;
    }
    
    IERC20ImplUpgradeable public erc20Proxy;

    uint256 public totalSupply;    
    mapping (address => uint256) public balances;
    mapping (address => Balance[]) public lockBalances;
    mapping (address => mapping (address => uint256)) public allowed;

    event UpdateProxy(address _old, address _new);

    constructor(address _proxy) public Authorization(_proxy) {
        totalSupply = 0;
    }

    function updateProxy(address _erc20Proxy) external onlyAdmin(msg.sender) {
        address _old = erc20Proxy;
        erc20Proxy = IERC20ImplUpgradeable(_erc20Proxy);
        emit UpdateProxy(_old, _erc20Proxy);
    }

    modifier onlyImpl {
        require(erc20Proxy.isImplAddress(msg.sender), "Only Impl can call");
        _;
    }

    function setTotalSupply(uint256 _newTotalSupply) public onlyImpl {
        totalSupply = _newTotalSupply;
    }

    function setAllowance(
        address _owner, 
        address _spender, 
        uint256 _value) 
        public 
        onlyImpl 
    {
        allowed[_owner][_spender] = _value;
    }

    function setBalance(address _owner, uint256 _newBalance) public onlyImpl {
        balances[_owner] = _newBalance;
    }

    function addBalance(address _owner, uint256 _balanceIncrease) public onlyImpl {
        balances[_owner] = balances[_owner].add(_balanceIncrease);
    }

    function setLockBalance(
        address _owner, 
        uint256 _newBalance, 
        uint256 _timestamp
    ) 
        public 
        onlyImpl 
    {
        Balance[] storage lockbalance = lockBalances[_owner];
        for(uint i = 0; i < lockbalance.length; ++i){
            if(_timestamp == lockbalance[i].timestamp) {
                if(now >= _timestamp){
                    uint newBalance = balances[_owner];
                    newBalance = newBalance.add(lockbalance[i].value);
                    balances[_owner] = newBalance;
                }
                lockbalance[i].value = _newBalance;
            }
        }
    }

    function addLockBalance(
        address _owner, 
        uint256 _balanceIncrease, 
        uint256 _timestamp
    ) 
        public 
        onlyImpl 
    {
        require(_timestamp > 0, "_timestamp need greater than 0");

        Balance[] storage balance = lockBalances[_owner];
        uint insertIndex = balance.length;
        for(uint i = 0; i < balance.length; ++i){
            if(insertIndex == balance.length && balance[i].timestamp == 0) {
                insertIndex = i;
                continue;
            }
            if(balance[i].timestamp == _timestamp) {
                balance[i].value = balance[i].value.add(_balanceIncrease);
                return;
            }
        }
        if(insertIndex == balance.length)
            balance.push(Balance(_timestamp, _balanceIncrease));
        else {
            balance[insertIndex].timestamp = _timestamp;
            balance[insertIndex].value = _balanceIncrease;
        }
    }

    function adjustLockBalance(address _owner) public onlyImpl {
        Balance[] storage lockbalance = lockBalances[_owner];
        uint newBalance = balances[_owner];
        for(uint i = 0; i < lockbalance.length; ++i){
            if(now >= lockbalance[i].timestamp) {
                newBalance = newBalance.add(lockbalance[i].value);
                delete lockbalance[i];
            }
        }
        balances[_owner] = newBalance;
    }

    function sweep(address _owner) public onlyImpl returns(uint256 balance) {
        balance = balances[_owner];
        Balance[] storage lockbalance = lockBalances[_owner];
        for(uint i = 0; i < lockbalance.length; ++i){
            balance += lockbalance[i].value;
        }
        
        delete lockBalances[_owner];
        delete balances[_owner];
    }

    function getBalance(address _owner) public view returns(uint256 balance) {
        balance = balances[_owner];
        Balance[] storage lockBalance = lockBalances[_owner];
        for(uint i = 0; i < lockBalance.length; ++i){
            if(now >= lockBalance[i].timestamp) {
                balance += lockBalance[i].value;
            }
        }
    }

    function getLockBalance(address _owner, uint256 _timestamp) public view returns(uint256) {
        if(now >= _timestamp) {
            return 0;
        }
        Balance[] storage lockBalance = lockBalances[_owner];
        for(uint i = 0; i < lockBalance.length; ++i){
            if(_timestamp == lockBalance[i].timestamp) {
                return lockBalance[i].value;
            }
        }
        return 0;
    }

    function getAllLockBalances(address _owner) 
        public 
        view 
        returns(
            uint256[] lockBalanceTimestamps, 
            uint256[] lockBalanceValues
        ) 
    {
        Balance[] storage lockBalance = lockBalances[_owner];
        lockBalanceTimestamps = new uint256[](lockBalance.length);
        lockBalanceValues = new uint256[](lockBalance.length);
        uint j = 0;
        for(uint i = 0; i < lockBalance.length; ++i){
            if(now < lockBalance[i].timestamp) {
                lockBalanceTimestamps[j] = lockBalance[i].timestamp;
                lockBalanceValues [j] = lockBalance[i].value;
                ++j;
            }
        }
    }
}

