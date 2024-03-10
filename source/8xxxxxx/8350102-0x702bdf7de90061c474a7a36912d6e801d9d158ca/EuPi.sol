pragma solidity 0.5.7;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ----------------------------------------------------------------------------
// 'EuPi' token contract
//
// Symbol      : EuPi
// Name        : EuPi 
// Total supply: 100,000,000
// Decimals    : 18
//
// Contact: <info@cryptopi.fund>, http://CryptoPi.fund
//
//
// Inspired by a contract template 
// from https://github.com/bitfwdcommunity/Issue-your-own-ERC20-token
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    uint256 constant private MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd (uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert (x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub (uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert (x >= y);
        return x - y;
    }

    function safeMul (uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        assert (x <= MAX_UINT256 / y);
        return x * y;
    }
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address internal owner;
    address internal ownerToTransferTo;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        ownerToTransferTo = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == ownerToTransferTo);
        emit OwnershipTransferred(owner, ownerToTransferTo);
        owner = ownerToTransferTo;
        ownerToTransferTo = address(0);
    }
}

// ----------------------------------------------------------------------------
// Pausable contract
// ----------------------------------------------------------------------------
contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier notPaused() {
        require(!paused, "this contract is suspened, come later");
        _;
    }

    modifier whenPaused() {
        require(paused, "contract must be paused");
        _;
    }

    function pause() public onlyOwner notPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

// ----------------------------------------------------------------------------
// Transfer fees abstraction
// ----------------------------------------------------------------------------
contract TransferFee is Owned, SafeMath {

    event ChangedFee (
        uint256 fixedFee,
        uint256 minVariableFee,
        uint256 maxVariableFee,
        uint256 variableFee
    );

    // Variable fee is denomintated in 0.001% with maximum 100%
    uint256 constant internal VARIABLE_FEE_DENOMINATOR = 100000;

    mapping (address => bool) internal zeroFeeAddress;
    address internal feeCollector; // address recieving fees
    uint256 internal flatFee; // flat fee in tokens
    uint256 internal variableFee; // variable fee in denominated %%
    uint256 internal minVariableFee; // minumum variable fee in tokens
    uint256 internal maxVariableFee; // maximum variable fee in tokens

    constructor () public {
        flatFee = 0; // in tokens
        variableFee = 100; // in denominated %%, 0.1% = 1000 * 0.1
        minVariableFee = 0; // in tokens
        maxVariableFee =  // in tokens, not limited
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff - flatFee;
        feeCollector = owner;

        zeroFeeAddress[address(this)] = true;
    }

    function calculateFee (address from, address to, uint256 amount) public view returns (uint256 _fee) {
        if (zeroFeeAddress[from] || from == owner) return 0;
        if (zeroFeeAddress[to] || to == owner) return 0;

        _fee = safeMul (amount, variableFee) / VARIABLE_FEE_DENOMINATOR;
        if (_fee < minVariableFee) _fee = minVariableFee;
        if (_fee > maxVariableFee) _fee = maxVariableFee;
        _fee = safeAdd (_fee, flatFee);
    }

    function setFeeCollector (address _newFeeCollector) public onlyOwner {
        feeCollector = _newFeeCollector;
    }

    function setZeroFee (address _address) public onlyOwner {
        zeroFeeAddress [_address] = true;
    }

    function getFeeParameters () public view returns (
        uint256 _flatFee,
        uint256 _minVariableFee,
        uint256 _maxVariableFee,
        uint256 _variableFee) 
    {
        _flatFee = flatFee;
        _minVariableFee = minVariableFee;
        _maxVariableFee = maxVariableFee;
        _variableFee = variableFee;
    }

    function setFeeParameters (
        uint256 _flatFee,
        uint256 _minVariableFee,
        uint256 _maxVariableFee,
        uint256 _variableFee) public onlyOwner
    {
        require (_minVariableFee <= _maxVariableFee, "minimum variable fee should be less than maximum one");
        require (_variableFee <= VARIABLE_FEE_DENOMINATOR, "variable fee should be less than 100%");

        flatFee = _flatFee;
        minVariableFee = _minVariableFee;
        maxVariableFee = _maxVariableFee;
        variableFee = _variableFee;

        emit ChangedFee (_flatFee, _minVariableFee, _maxVariableFee, _variableFee);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract EuPi is IERC20, Owned, Pausable, SafeMath, TransferFee {
    string public constant symbol = "EuPi";
    string public constant name = "EuPi";
    uint8 public constant decimals = 18; // !!! It must be 18, until decimals alignment is implemented in ()
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        // 100,000,000 and 18 decimals
        _totalSupply = 100000000000000000000000000;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint256) {
        return _totalSupply - _balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return _balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - zero amount transfers are _allowed, but do nothing
    // - We don't check it the contract is paused, take care in a public method
    // ------------------------------------------------------------------------
    function noFeeTransfer(address to, uint256 tokens) internal returns (bool success) {
        require(to != address(0), "not zero address is required");

        uint256 fromBalance = _balances [msg.sender];
        if (fromBalance < tokens) return false;
        if (tokens > 0 && msg.sender != to) {
            _balances [msg.sender] = safeSub (fromBalance, tokens);
            _balances [to] = safeAdd (_balances [to], tokens);
        }
        // to simplify consumer app logic we emit event even if nothing has been changed
        emit Transfer (msg.sender, to, tokens);
        return true;
    }

    function transfer(address to, uint256 tokens) public notPaused returns (bool success) {
        uint256 fee = calculateFee (msg.sender, to, tokens);
        if (tokens <= _balances [msg.sender] &&
          fee <= safeSub (_balances [msg.sender], tokens)) {
            // we've done all the prechecks before, following transfers must never fail
            assert (noFeeTransfer (to, tokens));
            assert (noFeeTransfer (feeCollector, fee));
            return true;
        } else return false;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public notPaused 
    returns (bool success) {
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // - The calling account must already have sufficient allowance (approved tokens) 
    // for spending from the from account
    // - From account must have sufficient balance to transfer
    // - Zero amount transfers are _allowed
    // - We don't check it the contract is paused, take care in a public method
    // ------------------------------------------------------------------------
    function noFeeTransferFrom (address from, address to, uint256 tokens) 
    internal returns (bool success) {
        require(to != address(0), "not zero address is required");

        uint256 allowance = _allowed [from][msg.sender];
        if (allowance < tokens) return false;
        uint256 fromBalance = _balances [from];
        if (fromBalance < tokens) return false;

        if (tokens > 0 && from != to) {
            _balances [from] = safeSub (fromBalance, tokens);
            _allowed [from][msg.sender] = safeSub (allowance, tokens);
            _balances [to] = safeAdd (_balances [to], tokens);
        }
        // to simplify consumer app logic we emit event even if nothing has been changed
        emit Transfer (from, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public notPaused 
    returns (bool success) {
        require(to != address(0), "not zero address is required");
        
        uint256 fee = calculateFee (msg.sender, to, tokens);
        uint256 fromBalance = _balances [from];
        uint256 allowance = _allowed [from][msg.sender];

        // after deduction of the principal amount:
        // - there must be enough allowance to cover transaction fee
        // - there must be enough balance to cover transaction fee  
        if (
            tokens <= allowance && fee <= safeSub (allowance, tokens) && 
            tokens <= fromBalance && fee <= safeSub (fromBalance, tokens)
            )
        {
            // we've done all the prechecks before, following transfers must never fail
            assert (noFeeTransferFrom (from, to, tokens));
            assert (noFeeTransferFrom (from, feeCollector, fee));
            return true;
        } else return false;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view 
    returns (uint256 remaining) {
        return _allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve spender to transferFrom(...) tokens
    // from the token owner account. The spender contract function
    // receiveApproval(...) is then executed
    // Borrowed from MiniMeToken
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint256 tokens, bytes memory data) public notPaused
    returns (bool _success) {
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can increase approval for spender to transferFrom(...) tokens
    // from the token owner's account.
    // From MonolithDAO Token.sol
    // ------------------------------------------------------------------------
    function increaseApproval(address spender, uint256 addedValue) public notPaused 
    returns (bool) {
        _allowed[msg.sender][spender] = (
            safeAdd(_allowed[msg.sender][spender], addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can reduce approval for spender to transferFrom(...) tokens
    // from the token owner's account.
    // From MonolithDAO Token.sol
    // ------------------------------------------------------------------------
    function decreaseApproval(address spender, uint256 substractedValue) public notPaused
    returns (bool) {
        uint256 oldValue = _allowed[msg.sender][spender];
        if (substractedValue > oldValue) {
            _allowed[msg.sender][spender] = 0;
        } else {
            _allowed[msg.sender][spender] = safeSub(oldValue, substractedValue);
        }
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    // ------------------------------------------------------------------------
    // Allows any ERC20 tokens accidentially sent to this contract's address 
    // to be transferred out
    // ------------------------------------------------------------------------
    function claimERC20(address tokenAddress, address to, uint256 amount) public onlyOwner returns (bool _success) {
        return 
            IERC20(tokenAddress).transfer(
                to,
                amount > 0 ? amount : 
                    IERC20(tokenAddress).balanceOf(address(this))
            );
    }

    function claimETH(address payable to, uint256 amount) public returns (bool _success) {
        require(msg.sender == owner);
        return to.send(amount);
    }
}
