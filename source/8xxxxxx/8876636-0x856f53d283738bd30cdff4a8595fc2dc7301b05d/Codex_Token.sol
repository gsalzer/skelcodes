pragma solidity ^0.5.12;

// ----------------------------------------------------------------------------
// "Codex Token contract"
//
// Deployed to : 0x60e6f7313af29946b68389bfc7bccd54a8e9e5b2
// Symbol      : COD1
// Name        : Codex Token
// Total supply: 250000000
// Decimals    : 8
//
// Contract Developed by Osiz Technologies
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20 {
    function balanceOf(address owner) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ----------------------------------------------------------------------------
// Token contract
// ----------------------------------------------------------------------------
contract Codex_Token is ERC20 {
    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    address internal _admin;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ERC20 Token, with the addition of symbol, name and decimals and assisted
    // ------------------------------------------------------------------------
    constructor() public {
        _symbol = "COD1";  
        _name = "Codex Token"; 
        _decimals = 8;
        _totalSupply = 250000000* 10**uint(_decimals);
        _admin = msg.sender;
        balances[_admin] = _totalSupply;
    }
    
    // ----------------------------------------------------------------------------
    // Safe math functions
    // ----------------------------------------------------------------------------

    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        assert(b <= a);
        return a - b;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    
    // ------------------------------------------------------------------------
    // Get token balance 
    // ------------------------------------------------------------------------
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from msg.sender account to _to account
    // - Owner's account must have sufficient balance to transfer
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
        emit ERC20.Transfer(msg.sender, _to, _value);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer tokens from the _from account to _to account
    // The calling account must already have sufficient tokens and approved
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = sub(balances[_from], _value);
        balances[_to] = add(balances[_to], _value);
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender], _value);
        emit ERC20.Transfer(_from, _to, _value);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        allowed[msg.sender][_spender] = _value;
        emit ERC20.Approval(msg.sender, _spender, _value);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Mint Additonal tokens
    // Only admin can mint tokens
    // ------------------------------------------------------------------------
    function mint(uint256 _amount) public returns (bool) {
        require(_admin == msg.sender);
        _totalSupply = add(_totalSupply,_amount);
        balances[_admin] = add(balances[_admin],_amount);
        return true;
    }
  
}
