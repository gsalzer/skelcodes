pragma solidity ^0.5.0;

// ERC20 protocol Interface
contract ERC20Interface {
    
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
}

contract WorkToken is ERC20Interface {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    address public owner;
    
    // to maintain token balances
    mapping(address => uint) balances;
    
    mapping(address => mapping(address => uint)) allowed;
    
    // defining token
    constructor() public {
        symbol = "WRC";
        name = "WorkQuest Token";
        decimals = 18;
        _totalSupply = 200000000 * 10**uint(decimals);
        owner = msg.sender;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function totalSupply() public view returns (uint) {
        // Or return balances[address(0)] only, since tokens are deducted from here?
        return _totalSupply - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        require(owner != msg.sender, "Owner cannot buy tokens");
        // transfer call by tourist to buy tokens
        if(msg.sender == to) {
            balances[owner] = balances[owner] - tokens;
            balances[to] = balances[to] + tokens;
            emit Transfer(owner, to, tokens);
            return true;
        }
        // transfer call to buy product by tourist
        else {
        // deduct tourist token balance
        balances[msg.sender] = balances[msg.sender] - tokens;
        // increment productOwner balance
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
        }
        
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(tokens<balances[from],"Not enough balance for this transaction");
        balances[from] = balances[from]-tokens;
        allowed[from][msg.sender] = allowed[from][msg.sender]-tokens;
        balances[to] = balances[to]+tokens;
        
        
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
}
