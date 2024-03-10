pragma solidity ^0.6.6;


interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transfer(address to, uint value) external returns(bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Burn(address indexed from, uint256 value);
}

library SafeMath{
      function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) {
        return 0;}
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}
contract Tipcoin is ERC20 {
    
    using SafeMath for uint256;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    
    address internal _admin;
    

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
  

    constructor() public {
        _admin = msg.sender;
        _symbol = "TIP";  
        _name = "Tipcoin"; 
        _decimals = 18; 
        _totalSupply = 1000000000* 10**uint(_decimals);
        balances[msg.sender]=_totalSupply;
       
    }
    
    modifier ownership()  {
    require(msg.sender == _admin);
        _;
    }
    
  
    function name() public view returns (string memory) 
    {
        return _name;
    }

    function symbol() public view returns (string memory) 
    {
        return _symbol;
    }

    function decimals() public view returns (uint8) 
    {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) 
    {
        return _totalSupply;
    }

   function transfer(address _to, uint256 _value) public  override returns (bool) {
     require(_to != address(0));
     require(_value <= balances[msg.sender]);
     balances[msg.sender] = balances[msg.sender].sub(_value);
     balances[_to] = (balances[_to]).add( _value);
     emit ERC20.Transfer(msg.sender, _to, _value);
     return true;
   }

  function balanceOf(address _owner) public override view returns (uint256 balance) {
    return balances[_owner];
   }

  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
     require(_to != address(0));
     require(_value <= balances[_from]);
     require(_value <= allowed[_from][msg.sender]);

    balances[_from] = (balances[_from]).sub( _value);
    balances[_to] = (balances[_to]).add(_value);
    allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_value);
    emit ERC20.Transfer(_from, _to, _value);
     return true;
   }

   function approve(address _spender, uint256 _value) public override returns (bool) {
     allowed[msg.sender][_spender] = _value;
    emit ERC20.Approval(msg.sender, _spender, _value);
     return true;
   }

  function allowance(address _owner, address _spender) public override view returns (uint256) {
     return allowed[_owner][_spender];
   }
   
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }
   
   function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

 
    
 function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        _totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
     
  
  
 
  
  //Admin can transfer his ownership to new address
  function transferownership(address _newaddress) public returns(bool){
      require(msg.sender==_admin);
      _admin=_newaddress;
      return true;
  }
  
    
}
