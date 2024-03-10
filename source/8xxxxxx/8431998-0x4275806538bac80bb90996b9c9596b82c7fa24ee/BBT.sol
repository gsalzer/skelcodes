pragma solidity "0.5.10";

/* =========================================================================================================*/
// ----------------------------------------------------------------------------
// Bit-Bet (BBT) token contract
//
// Total supply: 10M
// Decimals    : 18
// ----------------------------------------------------------------------------
// Coding and Development by Crypterx.com
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return div(mul(d,m),m);
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract BBT is ERC20Interface, Owned {
    using SafeMath for uint;
    
    string public symbol = "BBT";
    string public  name = "Bit-Bet";
    uint8 public decimals = 18;
    uint internal _totalSupply;
    uint256 internal extras = 100;
    
    address public donation;
    address public distribution;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _owner, address _donation, address _distribution) public {
        _mint(_owner, 10e6 * 10**uint(decimals));
        owner = _owner;
        distribution = _distribution;
        donation = _donation;
    }
    
    // ------------------------------------------------------------------------
    // Don't Accepts ETH
    // ------------------------------------------------------------------------
    function () external payable {
        revert();
    }
    
    // ------------------------------------------------------------------------
    // Calculates onePercent of the uint256 amount sent
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) internal view returns (uint256){
        uint roundValue = _tokens.ceil(extras);
        uint onePercentofTokens = roundValue.mul(extras).div(extras * 10**uint(2));
        return onePercentofTokens;
    }
     
    // ------------------------------------------------------------------------
    // @dev Destroys `amount` tokens from `account`, reducing the total supply.
    // Emits a {Transfer} event with `to` set to the zero address.
    //
    // Requirements
    // - `account` cannot be the zero address.
    // - `account` must have at least `amount` tokens.
    // ------------------------------------------------------------------------
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        emit Transfer(account, address(0), value);
    }
     
    // ------------------------------------------------------------------------
    // @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply.
    // Emits a {Transfer} event with `from` set to the zero address.
    //
    // Requirements
    // - `to` cannot be the zero address.
    // ------------------------------------------------------------------------
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    // ------------------------------------------------------------------------
    // @dev keep 'amount' of tokens into 'to' wallet
    // ------------------------------------------------------------------------
    function _transfer(address from, address to, uint256 amount) internal {
        balances[from] =  balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(from, address(to), amount);
    }
    
    // ------------------------------------------------------------------------
    // Get the total Supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint){
       return _totalSupply;
    }
    
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // Deductions apply
    // keep 1% of the sent amount for donation
    // keep 1% for token holders to send them later
    // burn 1% of the sent amount of tokens
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        // prevent transfer to 0x0, use burn instead
        require(to != address(0));
        require(balances[msg.sender] >= tokens );
        
        __transfer(to, msg.sender, tokens);
        
        return true;
    }
    
    // ------------------------------------------------------------------------
    // internal function applies Deductions upon transfer function
    // ------------------------------------------------------------------------
    function __transfer(address to, address from, uint tokens) internal {
        // calculate 1% of the tokens
        uint256 onePercentofTokens = onePercent(tokens);
        
        // burn 1% of tokens
        _burn(from, onePercentofTokens);
        
        // transfer 1% to donation wallet
        _transfer(from, donation, onePercentofTokens);
        
        // distribute 1% to token holders
        _transfer(from, distribution, onePercentofTokens);
        
        balances[from] = balances[from].sub(tokens.sub(onePercentofTokens.mul(3)));
        
        // transfer rest of the tokens to the receipient
        require(balances[to] + tokens.sub(onePercentofTokens.mul(3)) >= balances[to]);
        
        // Transfer the tokens to "to" address
        balances[to] = balances[to].add(tokens.sub(onePercentofTokens.mul(3)));
        
        // emit Transfer event to "to" address
        emit Transfer(from,to,tokens.sub(onePercentofTokens.mul(3)));
    }
    
    
    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // Deductions apply
    // keep 1% of the sent amount for donation
    // keep 1% for token holders to send them later
    // burn 1% of the sent amount of tokens
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(from != address(0));
        require(to != address(0));
        require(tokens <= allowed[from][msg.sender]); //check allowance
        require(balances[from] >= tokens); // check if sufficient balance exist or not
        
        __transfer(to, from, tokens);
        
        
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success){
        require(spender != address(0));
        require(tokens <= balances[msg.sender]);
        require(tokens >= 0);
        require(allowed[msg.sender][spender] == 0 || tokens == 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
}
