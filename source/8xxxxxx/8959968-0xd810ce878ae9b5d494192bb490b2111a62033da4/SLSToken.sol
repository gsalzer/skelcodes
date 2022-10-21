pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./ERC20Interface.sol";

contract SLSToken is ERC20Interface{
    using SafeMath for uint256;
    using SafeMath for uint8;
    
    event ListLog(address addr, uint8 indexed typeNo, bool active);
    event Trans(address indexed fromAddr, address indexed toAddr, uint256 transAmount, uint64 time);
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event Deposit(address indexed sender, uint value);

    string public symbol;
    string public name;
    uint8 public decimals;    
    uint256 public _totalSupply;
    
    address public owner;
    address private ownerContract = address(0x0);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    mapping(address => bool) public blackList;
    
    constructor() public {
        symbol = "SLS";
        name = "SLS Coin";
        owner = msg.sender;
        decimals = 2;
        
        _totalSupply = 600 * 10**uint256(decimals);
        balances[owner] = _totalSupply;
        
        emit ListLog(owner, 1, true);
        emit Transfer(address(0x0), owner, _totalSupply);
    }
    
    function AssignOwner(address _ownerContract) 
    public 
    onlyOwner 
    notNull(_ownerContract) 
    {
        uint256 remainTokens = balances[owner];
        ownerContract = _ownerContract;
        balances[owner] = 0;
        balances[ownerContract] = balances[ownerContract].add(remainTokens);
        emit Transfer(owner, ownerContract, remainTokens);
        emit OwnershipTransferred(owner, ownerContract);
        owner = ownerContract;
    }

    function transfer(address _to, uint256 _value) 
    public 
    notNull(_to) 
    returns (bool success) 
    {
        require(balances[msg.sender] >= _value);
        success = _transfer(msg.sender, _to, _value);
        require(success);


        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Trans(msg.sender, _to, _value, uint64(now));
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) 
    public 
    notNull(_to) 
    returns (bool success) 
    {
        
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        success = _transfer(_from, _to, _value);
        require(success);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Trans(_from, _to, _value, uint64(now));
        return true;
    }


    function _transfer(address _from, address _to, uint256 _value) 
    internal 
    notNull(_from) 
    notNull(_to) 
    returns (bool) 
    {
        require(!blackList[_from]);
        require(!blackList[_to]);       
        
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }

    function approve(address _spender, uint256 _value) 
    public 
    returns (bool success) 
    {
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            return false;
        }

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _tokenOwner, address _spender) 
    public 
    view 
    returns (uint256 remaining) 
    {
        return allowed[_tokenOwner][_spender];
    }
    
    function() 
    payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    function tokenFallback(address from_, uint256 value_, bytes data_) 
    external 
    {
        from_;
        value_;
        data_;
        revert();
    }
    
    // ------------------------------------------------------------------------
    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0x0));
        _;
    }

    // ------------------------------------------------------------------------
    // onlyOwner API
    // ------------------------------------------------------------------------
    
    
    function addBlacklist(address _addr) public notNull(_addr) onlyOwner {
        blackList[_addr] = true; 
        emit ListLog(_addr, 3, true);
    }
    
    function delBlackList(address _addr) public notNull(_addr) onlyOwner {
        delete blackList[_addr];                
        emit ListLog(_addr, 3, false);
    }

    function transferAnyERC20Token(address _tokenAddress, uint256 _tokens) 
    public 
    onlyOwner 
    returns (bool success) 
    {
        return ERC20Interface(_tokenAddress).transfer(owner, _tokens);
    }

    function mintToken(address _targetAddr, uint256 _mintedAmount) 
    public 
    onlyOwner 
    {
        balances[_targetAddr] = balances[_targetAddr].add(_mintedAmount);
        _totalSupply = _totalSupply.add(_mintedAmount);
        
        emit Transfer(address(0x0), _targetAddr, _mintedAmount);
    }
 
    function burnToken(uint256 _burnedAmount) 
    public 
    onlyOwner 
    {
        require(balances[owner] >= _burnedAmount);
        
        balances[owner] = balances[owner].sub(_burnedAmount);
        _totalSupply = _totalSupply.sub(_burnedAmount);
        
        emit Transfer(owner, address(0x0), _burnedAmount);
    }

    function increaseApproval(address _spender, uint256 _addedValue) 
    public 
    notNull(_spender) 
    onlyOwner returns (bool) 
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
   }

    function decreaseApproval(address _spender, uint256 _subtractedValue) 
    public 
    notNull(_spender) 
    onlyOwner returns (bool) 
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) { 
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    // ------------------------------------------------------------------------
    // Public view API
    // ------------------------------------------------------------------------
    function balanceOf(address _tokenOwner) 
    public 
    view 
    returns (uint256 balance) 
    {
        return balances[_tokenOwner];
    }
    
    function totalSupply() 
    public 
    view 
    returns (uint256) 
    {
        return _totalSupply.sub(balances[address(0x0)]);
    }
}
