pragma solidity ^0.6.6;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://eips.ethereum.org/EIPS/eip-20
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address account) virtual public view returns (uint256 balance);
    function allowance(address account, address spender) virtual public view returns (uint256 remaining);
    function transfer(address to, uint256 amount) virtual public returns (bool success);
    function approve(address spender, uint256 amount) virtual public returns (bool success);
    function transferFrom(address account, address to, uint256 amount) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed account, address indexed spender, uint256 amount);
    event Burn(address indexed from, uint256 amount);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address account, uint256 amount, address token, bytes memory data) virtual public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract CMGCoin is ERC20Interface, Owned, SafeMath {
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    uint256 private _totalSupply;
    
    string public version = 'H1.0';
    
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        _name = "CMGCoin";
        _symbol = "CMG";
        _decimals = 8;
        _totalSupply = 10000000 * 10 ** uint256(_decimals);
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account account
    // ------------------------------------------------------------------------
    function balanceOf(address account) public override view returns (uint256 balance) {
        return balances[account];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 amount) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        balances[to] = safeAdd(balances[to], amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) amount
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 amount) public override returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer amount from the from account to the to account
    // 
    // The calling account must already have sufficient amount approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address account, address to, uint256 amount) public override returns (bool success) {
        balances[account] = safeSub(balances[account], amount);
        allowed[account][msg.sender] = safeSub(allowed[account][msg.sender], amount);
        balances[to] = safeAdd(balances[to], amount);
        emit Transfer(account, to, amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of amount approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address account, address spender) public override view returns (uint256 remaining) {
        return allowed[account][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) amount
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint256 amount, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    receive() external payable {
        revert();
    }
    
    // ------------------------------------------------------------------------
    // Destroy amount
    // ------------------------------------------------------------------------
    function burn(uint256 amount) public onlyOwner returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], amount * 10 ** uint256(_decimals));
        _totalSupply -= amount * 10 ** uint256(_decimals);
        emit Burn(msg.sender, amount * 10 ** uint256(_decimals));
        return true;
    }
}
