pragma solidity ^0.5.9;

/**
 * @title Math operations with safety checks for overflows.
 */
library SafeMath {
    /**
     * @dev Performs addition.
     * @param a first number
     * @param b second number
     * @return c addtion
     */
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a && c >= b);
    }

    /**
     * @dev Performs subtraction.
     * @param a first number
     * @param b second number, must be less or equal to a
     * @return c difference
     */
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    /**
     * @dev Performs multiplication.
     * @param a first number
     * @param b second number
     * @return c addtion
     */
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    /**
     * @dev Performs division.
     * @param a first number
     * @param b second number, cannot be 0
     * @return c addtion
     */
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

}


/**
 *  @title Binfinity token contract.
 */
contract BinfinityToken {
    using SafeMath for uint;
    
    /**
     * Token name.
     */
    string public name;

    /**
     * Token symbol.
     */
    string public symbol;

    /**
     * Number of decimal places.
     */
    uint8 public decimals;
    
    /**
     * Total suply.
     */
    uint public totalSupply;

    /**
     * Contract owner.
     */
    address payable public owner;
    
    /**
     * Balances.
     */
    mapping (address => uint) public balanceOf;
    
    /**
     * Freezings.
     */
    mapping (address => uint) public freezeOf;
    
    /**
     * Allowed transfers.
     */
    mapping (address => mapping (address => uint)) public allowance;

    /**
     * @dev Creates new instance. All tokens will be assigned to the contract owner.
     * @param initialSupply initial token supply
     * @param tokenName token name
     * @param numDecimals number of decimal units
     * @param tokenSymbol symbol of the token
     */
    constructor(string memory tokenName, string memory tokenSymbol, uint initialSupply, uint8 numDecimals) public {
        require(initialSupply > 0);
        require(numDecimals >= 0);
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = numDecimals;
        owner = msg.sender;
    }

    /**
     * @dev Fallback function which allows to accept payments.
     */
    function() external payable {
    }

    /**
     * @dev Transfers tokens from sender to the specified address.
     * @param _to destination address
     * @param _value number of tokens
     * @return success true on success
     */
    function transfer(address _to, uint _value) external returns (bool success){
        require(_to != address(0x0));
        require(_value > 0); 
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Allow another contract to spend tokens on the caller behalf.
     * Subsequent calls to this methods overrides the previous values.
     * @param _spender allowed spender who can spend tokens from callers account
     * @param _value allowed number of tokens
     * @return success true on success
     */
    function approve(address _spender, uint _value) external returns (bool success) {
        require(_value >= 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
       

    /**
     * @dev Transfers tokens from the specified address (if allowed).
     * @param _from address where the tyokens are taken from
     * @param _to address where the tokens are sent to
     * @param _value number of tokens to transfer
     * @return success true on success
     */
    function transferFrom(address _from, address _to, uint _value) external returns (bool success) {
        require(_to != address(0x0));
        require(_value > 0); 
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Burns tokens.
     * @param _value the number of token to burn
     * @return success true on success
     */
    function burn(uint _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_value > 0);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
    /**
     * @dev Freezes tokens.
     * @param _value amount to freeze
     * @return success true on success
     */
    function freeze(uint _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_value > 0);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        freezeOf[msg.sender] = freezeOf[msg.sender].add(_value);
        emit Freeze(msg.sender, _value);
        return true;
    }
    
    /**
     * @dev Unfreezes tokens.
     * @param _value amount to unfreeze
     * @return success true on success
     */
    function unfreeze(uint _value) external returns (bool success) {
        require(freezeOf[msg.sender] >= _value);
        require(_value > 0);
        freezeOf[msg.sender] = freezeOf[msg.sender].sub(_value);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
    
    /**
     * @dev Withdraws ethereum.
     * @param amount amount to withdraw
     */
    function withdrawEther(uint amount) external {
        require(msg.sender == owner);
        owner.transfer(amount);
    }
 
    /**
     * @dev Transfer event.
     * @param _from payer address
     * @param _to revceiver address
     * @param _value number of transfered tokens
     */
    event Transfer(address indexed _from, address indexed _to, uint _value);

    /**
     * @dev Approval event.
     * @param _owner owner of the tokens
     * @param _spender who is allowed to spend tokens
     * @param _value the amount which can be spend
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    /**
     * @dev Burn event.
     * @param _from source account from which tokens are burned
     * @param _value number of burend tokens
     */
    event Burn(address indexed _from, uint _value);
    
    /**
     * @dev Token freezing event.
     * @param _from account where tokens got frozen
     * @param _value number of frozen tokens
     */
    event Freeze(address indexed _from, uint _value);
    
    /**
     * @dev Token unfreezing event.
     * @param _from account where tokens got released
     * @param _value number of unfrozen tokens
     */
    event Unfreeze(address indexed _from, uint _value);
        
}
