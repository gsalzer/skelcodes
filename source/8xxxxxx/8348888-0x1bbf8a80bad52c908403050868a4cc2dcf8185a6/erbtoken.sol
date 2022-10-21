pragma solidity ^0.5.7;

import './safemath.sol';

contract MaskCoin {
    using SafeMath for uint256;

    string constant public name = "Mask Coin";      //  token name
    string constant public symbol = "MASK";           //  token symbol
    uint256 public decimals = 18;            //  token digit

    //mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public frozenBalances; 
    mapping (address => uint256) public balances; 

    uint256 public totalSupply = 0;
    bool public stopped = false;
    
    address constant zeroaddr = address(0);
    address owner = zeroaddr;   
    address founder = zeroaddr; 

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier isFounder {
        assert(founder == msg.sender);
        _;
    }

    modifier isAdmin {
        assert(owner == msg.sender || founder == msg.sender);
        _;
    }

    modifier isRunning {
        assert (!stopped);
        _;
    }

    modifier validAddress {
        assert(zeroaddr != msg.sender);
        _;
    }

    constructor(address _addressFounder,uint256 _valueFounder) public {
        owner = msg.sender;
        founder = _addressFounder;
        totalSupply = _valueFounder*10**decimals;
        balances[founder] = totalSupply;
        emit Transfer(zeroaddr, founder, totalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        
        return balances[_owner] + frozenBalances[_owner];
    }

    function transfer(address _to, uint256 _value) public isRunning validAddress returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    
    function transferFrom(address _from, address _to, uint256 _value) public isRunning validAddress returns (bool success) {
        balances[_from] = balances[_from].sub(_value);
        //balances[_to] = balances[_to].add(_value);
        frozenBalances[_to] = frozenBalances[_to].add(_value); 
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit TransferFrozen(_to, _value);
        return true;
    }

    
    function approve(address _spender, uint256 _value) public isRunning isFounder returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0,"illegal operation");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    
    function release(address _target, uint256 _value) public isRunning isAdmin returns(bool){
        frozenBalances[_target] = frozenBalances[_target].sub(_value);
        balances[_target] = balances[_target].add(_value);
        emit Release(_target, _value);
        return true;
    }

    function stop() public isOwner {
        stopped = true;
    }

    function start() public isOwner {
        stopped = false;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TransferFrozen(address _target, uint256 _value);
    event Release(address _target, uint256 _value);
}
