pragma solidity ^0.4.26;


contract ERC20Standard {
    uint256 public totalSupply;
    string public name;
    uint8 public decimals;
    string public symbol;
    address public owner;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

   constructor(uint256 _totalSupply, string _symbol, string _name, uint8 _decimals) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        owner = msg.sender;
        totalSupply = _totalSupply * (10 ** uint256(decimals));
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
  }
    //Fix for short address attack against ERC20
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length == size + 4);
        _;
    } 

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _recipient, uint256 _value) onlyPayloadSize(2*32)  public returns (bool)  {
        require(_recipient != address(0));
        require(balances[msg.sender] >= _value && _value >= 0);
        require(balances[_recipient] + _value >= balances[_recipient]);
        balances[msg.sender] -= _value;
        balances[_recipient] += _value;
        emit Transfer(msg.sender, _recipient, _value);
        return true;      
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3*32)  public returns (bool)  {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value >= 0);
        require(balances[_to] + _value >= balances[_to]);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)  public returns (bool)  {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }

    //Event which is triggered to log all transfers to this contract's event log
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
        );
        
    //Event which is triggered whenever an owner approves a new allowance for a spender.
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
        );

}
