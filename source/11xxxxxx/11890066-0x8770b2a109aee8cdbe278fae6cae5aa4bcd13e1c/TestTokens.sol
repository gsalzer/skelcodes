pragma solidity 0.4.24;

contract TestTokens {
//Variables
string public name;
string public symbol; // Usually is 3 or 4 letters long
uint8 public decimals; // maximum is 18 decimals
uint256 public supply;

mapping(address => uint) public balances;
mapping(address => mapping(address => uint)) public allowed;
//Events
event Transfer(address sender, address receiver, uint256 tokens);
event Approval(address sender, address delegate, uint256 tokens);
//constructor
constructor (string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    supply = _supply * 10**18;
    balances[msg.sender] = _supply * 10**18;
}
//Functions
//return the total number of tokens that you have
function totalSupply() external view returns (uint256){
    return supply;
} 

//How many tokens does this person have
function balanceOf(address tokenOwner) external view returns (uint){
    return balances[tokenOwner];
} 

//helps in transferring from your account to another person
function transfer(address receiver, uint numTokens) external returns (bool){
    require(msg.sender != receiver,"Sender and receiver can't be the same");
    require(balances[msg.sender] >= numTokens,"Not enough balance");
    balances[msg.sender] -= numTokens;
    balances[receiver] += numTokens;
    emit Transfer(msg.sender,receiver,numTokens);
    return true;
} 

// Used to delegate authority to send tokens without my approval
function approve(address delegate, uint numTokens) external returns (bool){
    require(msg.sender != delegate,"Sender and delegate can't be the same");
    allowed[msg.sender][delegate] = numTokens;
    emit Approval(msg.sender,delegate,numTokens);
    return true;
} 

// How much has the owner delegated/approved to the delegate
function allowance(address owner, address delegate) external view returns (uint){
    return allowed[owner][delegate];
} 

// Used by exchanges to send money from owner to buyer
function transferFrom(address owner, address buyer, uint numTokens) external returns (bool){
    require(owner != buyer,"Owner and Buyer can't be the same");
    require(balances[owner] >= numTokens,"Not enough balance");
    require(allowed[owner][msg.sender] >= numTokens,"Not enough allowance");
    balances[owner] -= numTokens;
    balances[buyer] += numTokens;
    allowed[owner][msg.sender] -= numTokens;
    emit Transfer(owner,buyer,numTokens);
    return true;
}

// Should not be used in production
// Only to allocate testnet tokens to user for testing purposes
function allocateTo(address _owner, uint256 value) public {
        balances[_owner] += value;
        supply += value;
        emit Transfer(address(this), _owner, value);
    }
}
