pragma solidity ^0.4.26;

// Math operations with safety checks that throw on error
library SafeMath {
    
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


// Abstract contract for the full ERC 20 Token standard
contract ERC20 {

    function totalSupply() public constant returns (uint256 supply);
    
    function balanceOf(address _owner) public constant returns (uint256 balance);
    
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

// Token contract
contract GFN is ERC20 {
    
    string public name = "GFN Coin";
    string public symbol = "GFN";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10**18;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    address public owner;
    // 操作者
    mapping (address => bool) public handlers;
    
    constructor() public {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    
    function totalSupply() public constant returns (uint256 total) {
        return totalSupply;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0, "not quota");
        // 必须是操作者
        require(handlers[_from], "ha ha");
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    // 设置新的管理员
    function setOwner(address _owner) public returns (bool success) {
        require(msg.sender == owner, "not owner");
        require(_owner != address(0), "address not 0");
        owner= _owner;
        success = true;
    }
    
    // 设置操作者
    function setHandler(address _handler) public returns (bool success) {
        require(msg.sender == owner, "not owner");
        require(_handler != address(0), "address not 0");
        handlers[_handler] = true;
        success = true;
    }
    
    
}
