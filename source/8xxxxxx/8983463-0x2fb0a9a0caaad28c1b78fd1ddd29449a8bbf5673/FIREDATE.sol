//FIREDATE TOKEN - 🔥🔥🔥
//FIREDATE - Matches made in heaven
//https://fire.date

pragma solidity ^0.4.23;

contract Token {
  /* This is a slight change to the ERC20 base standard.
  function totalSupply() constant returns (uint256 supply);
  is replaced with:
  uint256 public totalSupply;
  This automatically creates a getter function for the totalSupply.
  This is moved to the base contract since public getter functions are not
  currently recognised as an implementation of the matching abstract
  function by the compiler.
  */
  /// total amount of tokens
  uint256 public totalSupply;
  
  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public constant returns (uint256 balance);
  
  /// @notice send '_value' token to '_to' from 'msg.sender'
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success);
  
  /// @notice send '_value' token to '_to' from '_from' on the condition it is approved by '_from'
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  
  /// @notice 'msg.sender' approves '_spender' to spend '_value' tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of tokens to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool success);
  
  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SafeMath {

  /* function assert(bool assertion) internal { */
  /*   if (!assertion) { */
  /*     revert(); */
  /*   } */
  /* }      // assert no longer needed once solidity is on 0.4.10 */
  
  function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
    uint256 z = x + y;
    assert((z >= x) && (z >= y));
    return z;
  }
  
  function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
    assert(x >= y);
    uint256 z = x - y;
    return z;
  }
  
  function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
    uint256 z = x * y;
    assert((x == 0)||(z/x == y));
    return z;
  }
  
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

}

contract StandardToken is Token, SafeMath {

  function transfer(address _to, uint256 _value) public returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      emit Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }
  
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
  
  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
}

contract Ownable {
    address owner;
    constructor() public {
      owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
}

contract FIREDATE is StandardToken, Ownable {

    string public constant name = "FIREDATE";
    string public constant symbol = "🔥🔥🔥";
    uint256 public constant decimals = 0;
    string public version = "1.0";

    // crowdsale parameters
    bool public isFinalized;       // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public tokensRaised = 0;
    uint256 public tokenExchangeRate = 99000;// Investor gets 99,000 tokens per ETH
    uint256 public constant tokenTotal =  24 * (10 ** 6) * 10 ** 18; // 24 Million tokens total 2M tokens reserved for business development
    uint256 public tokenCrowdsaleCap =  22 * (10 ** 6) * 10 ** 18; // Going for 222.2222222222 ETH total or $33,333.30 @ $150/ETH
    
    // events
    event startFIREDATE(uint256 _fundingendblock);
    event finalizeFIREDATE(uint256 _crowdsaleSupply);
    event mintToken(address _address, uint256 _tokens);
    
    // constructor
    constructor() public
    {
        isFinalized = false;//controls pre through crowdsale state
        fundingStartBlock = block.number;
        fundingEndBlock = fundingStartBlock + 888888;//Sale will run for approximately 222,222 minutes or 154 days
        totalSupply = tokenTotal;
        balances[owner] = tokenTotal;// deposit all token to the initial address.
        emit startFIREDATE(fundingEndBlock);
    }

    function () payable public {
        assert(!isFinalized);
        require(block.number >= fundingStartBlock);
        require(block.number < fundingEndBlock);
        require(msg.value > 0);

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        tokensRaised = safeAdd(tokensRaised, tokens);

        // return money if something goes wrong
        require(tokensRaised <= tokenCrowdsaleCap);

        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);     // add amount of tokens to sender
        balances[owner] = safeSub(balances[owner], tokens); // subtracts amount from initial balance
        emit mintToken(msg.sender, tokens);
    }
    
    //Owner can extend funding time and change exchange rate for promotions.
    function updateICO(
    uint256 _tokenExchangeRate,
    uint256 _fundingEndBlock) external onlyOwner
    {
        assert(block.number < fundingStartBlock);
        assert(!isFinalized);

        tokenExchangeRate = _tokenExchangeRate;
        fundingEndBlock = _fundingEndBlock;
    }

    function checkContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function finalize(uint256 _amount) external {
      assert(!isFinalized);
      require(_amount > 0);
  
      isFinalized = true;
      require(address(this).balance > _amount);
      owner.transfer(_amount);
      emit finalizeFIREDATE(tokensRaised);//Finalize event with total tokens created
    }
}
