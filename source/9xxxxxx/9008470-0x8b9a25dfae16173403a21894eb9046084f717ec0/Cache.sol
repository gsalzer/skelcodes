pragma solidity 0.5.11;

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable private owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    constructor(address payable _owner) public {
        owner = _owner;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function getOwner() internal view returns(address){
        return owner;
    }
    
    function transferOwnership(address payable _newOwner) public onlyOwner {
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
    function transferFrom(address payable from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

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
}

contract Cache is Owned(msg.sender), ERC20Interface{
    using SafeMath for uint256;
    
    /* ERC20 public vars */
    string public constant version = 'Cache 3.0';
    string public name = 'Cache';
    string public symbol = 'CACHE';
    uint256 public decimals = 18;
    uint256 internal _totalSupply;

    /* ERC20 This creates an array with all balances */
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    

    /* Keeps record of Depositor's amount and deposit time */
    mapping (address => Depositor) public depositor;
    
    struct Depositor{
        uint256 amount;
    }

    /* reservedReward collects owner reward share */
    uint256 public reservedReward;
    uint256 public constant initialSupply = 4e6;                                                //4,000,000
    
    /* custom events to notify users */
    event Withdraw(address indexed by, uint256 amount, uint256 fee);                            // successful withdraw event
    event Deposited(address indexed by, uint256 amount);                                        // funds Deposited event
    event PaidOwnerReward(uint256 amount);
    /*
     * Initializes contract with initial supply tokens to the creator of the contract
     * In our case, there's no initial supply. Tokens will be created as ether is sent
     * to the fall-back function. Then tokens are burned when ether is withdrawn.
     */
    Owned private owned;
    address payable private owner;
     
    constructor () payable public {
        owner = address(uint160(getOwner()));
        _totalSupply = initialSupply * 10 ** uint(decimals);                            // Update total supply
        balances[owner] = _totalSupply;                                                 // Give the creator all initial tokens
        emit Transfer(address(0),address(owner), _totalSupply);
    }

    /**
     * Fallback function when sending ether to the contract
     * Gas use: 91000
    */
    function() external payable {                                                   
        makeDeposit(msg.sender, msg.value);
    }
    
    //Pay the owner the reservedReward
    function ownerReward() internal{
        require(owner.send(reservedReward));
        emit PaidOwnerReward(reservedReward);
        reservedReward = reservedReward.sub(reservedReward);
    }
    
    //Charge a 0.3% deposit fee
    function makeDeposit(address sender, uint256 amount) internal {
        require(balances[sender] == 0);
        require(amount > 0);
        
        //Take 0.3% of the fee and send it to the Owner of the contract
        uint256 depositFee = (amount.div(1000)).mul(3);
        uint256 newAmount  = (amount.mul(1000)).sub(depositFee.mul(1000));
        
        //Send the tokens to depositor of the Ethereum
        balances[sender] = balances[sender] + newAmount;                                // mint new tokens
        _totalSupply = _totalSupply + newAmount;                                 // track the supply
        emit Transfer(address(0), sender, newAmount);                                   // notify of the transfer event
        
        //Adding the fee to the reservedReward
        reservedReward = reservedReward.add(depositFee);
        
        //Adding the amount deposited to the depositor
        depositor[sender].amount = newAmount;
        emit Deposited(sender, newAmount);
    }
    
    
    //Charge a 0.3% withdrawal fee
    function withdraw(address payable _sender, uint256 amount) internal {
        
        uint256 withdrawFee = (amount.div(1000)).mul(3);
        uint256 newAmount   = (amount.mul(1000)).sub(withdrawFee.mul(1000));
        
        //Remove deposit in terms of ETH
        depositor[_sender].amount = depositor[_sender].amount.sub(amount);                               // remove deposit information from depositor record

        //Withdraw the amount from the contract and pay the fee
        require(_sender.send(newAmount.div(1000000)));                                                       // transfer ethers plus earned reward to sender
        emit Withdraw(_sender, newAmount.div(1000000), withdrawFee.div(1000));
        
        //Adding the fee to the reservedReward
        reservedReward = reservedReward.add(withdrawFee.div(1000));
    }
    
    
    /***************************** ERC20 implementation **********************/
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
    // ------------------------------------------------------------------------
    
    function transfer(address to, uint tokens) public returns (bool success) {
        if(msg.sender == owner) { require(tokens >= 1e18);}                         // minimum tokens sent by owner sould be >= 1
        require(to != address(0));                                                  // receiver address should not be zero-address
        require(balances[msg.sender] >= tokens );                                   // sender must have sufficient tokens to transfer
        
        uint256 bal1 = balances[address(this)]; 
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);                    // remove tokens from sender
            
        require(balances[to] + tokens >= balances[to]);                             // if tokens are sent to any other wallet address
        
        balances[to] = balances[to].add(tokens);                                    // Transfer the tokens to "to" address
        
        emit Transfer(msg.sender,to,tokens);                                        // emit Transfer event to "to" address

        if(to ==  address(this)){                                                   // if tokens are sent to contract address
            require(bal1 < balances[address(this)]);
                                                                                   // sender must be an actual depositor
            //If the sender is the owner then withdraw the reward
            //Otherwise its a user and let them withdraw the reward
            if(msg.sender == owner){
                ownerReward();
            }
            
            if(depositor[msg.sender].amount > 0){                                     // sender must be an actual depositor
                if(tokens > depositor[msg.sender].amount){
                    withdraw(msg.sender,  depositor[msg.sender].amount);  
                }else{
                    withdraw(msg.sender, tokens);                                       // perform withdraw 
                }
            }
            
            
            balances[to] = balances[to].sub(tokens);                                // remove tokens from sender balance
            _totalSupply = _totalSupply.sub(tokens);                                // remove sent tokens from totalSupply
            emit Transfer(to, address(0), tokens);                                  // emit Transfer event of burning
        }
        return true;
    }
    
    
    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address payable from, address to, uint tokens) public returns (bool success){
        require(from != address(0));
        require(to != address(0));
        require(tokens <= allowed[from][msg.sender]); //check allowance
        require(balances[from] >= tokens); // check if sufficient balance exist or not
        
        if(to == address(this)){
            if(from == owner)
                require(tokens == 1e18);
        }
        
        uint256 bal1 = balances[address(this)];
        balances[from] = balances[from].sub(tokens);
        
        require(balances[to] + tokens >= balances[to]);
        
        balances[to] = balances[to].add(tokens);                                            // Transfer the tokens to "to" address
        
        emit Transfer(from,to,tokens);                                                // emit Transfer event to "to" address

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        
        if(to ==  address(this)){                                                   // if tokens are sent to contract address
            require(bal1 < balances[address(this)]);
            
            if(msg.sender == owner){
                ownerReward();
            }
            
            if(depositor[msg.sender].amount > 0){                                     // sender must be an actual depositor
                withdraw(from, tokens);                                       // perform withdraw 
            }
            
            
            balances[to] = balances[to].sub(tokens);                                // remove tokens from sender balance
            
            _totalSupply = _totalSupply.sub(tokens);                                // remove sent tokens from totalSupply
            
            emit Transfer(to, address(0), tokens);                                  // emit Transfer event of burning
        }
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success){
        require(spender != address(0));
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
