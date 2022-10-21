pragma solidity 0.4.24;

contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract RegularToken is Token {

    function transfer(address _to, uint _value) returns (bool) {
        require(balances[msg.sender] > _value);
        //Default assumes totalSupply can't be over max (2^256 - 1).
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } 
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool) {
       if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public{
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract UnboundedRegularToken is RegularToken {

    uint constant MAX_UINT = 2**256 - 1;
    
    /// @dev ERC20 transferFrom, modified such that an allowance of MAX_UINT represents an unlimited amount.
    /// @param _from Address to transfer from.
    /// @param _to Address to transfer to.
    /// @param _value Amount to transfer.
    /// @return Success of transfer.
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        uint allowance = allowed[_from][msg.sender];
        if (balances[_from] >= _value
            && allowance >= _value
            && balances[_to] + _value >= balances[_to]
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            if (allowance < MAX_UINT) {
                allowed[_from][msg.sender] -= _value;
            }
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
}

contract PausableToken is UnboundedRegularToken,Pausable {
    function transfer(address _to,uint256 _value)
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }
}

contract SperaxToken is PausableToken {

    uint public totalSupply = 50*10**26;
    uint8 constant public decimals = 18;
    string constant public name = "SperaxToken";
    string constant public symbol = "SPA";
    
    event Burn(address indexed from, uint256 value);
    
    function burn(uint256 _value) returns (bool success) {
        require(balances[msg.sender] >= _value);
                  // Check if the sender has enough
        require(_value > 0);
	
        balances[msg.sender] = balances[msg.sender] - _value;                      // Subtract from the sender
        totalSupply = totalSupply - _value;                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function SperaxToken() {
        balances[msg.sender] = totalSupply;
        Transfer(address(0), msg.sender, totalSupply);
    }
}
