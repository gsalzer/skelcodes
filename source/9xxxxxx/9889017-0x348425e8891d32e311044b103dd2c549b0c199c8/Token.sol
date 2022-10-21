pragma solidity >=0.4.22 <0.6.0;

contract Token {
    
   string public name;
   string public symbol;
   uint8 public decimals = 0;
   uint256 public totalSupply;
   uint256 public unitsOneEthCanBuy;
   mapping(address => uint256) public balanceOf;
   mapping(address => mapping(address=>uint256)) public allowed;
   address public owner;
   
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  constructor() public {
      balanceOf[msg.sender] = 1000000000000 * 10 ** uint256(decimals);
      totalSupply = 1000000000000 * 10 ** uint256(decimals);
      name= "Iran Rial";
      symbol="RIAL";
      owner = msg.sender;
      emit Transfer(0,owner,totalSupply);
      
    
    }
    
    modifier onlyowner {
        require(msg.sender == owner);
        _;
    }
    function updatePrice(uint256 _price) public onlyowner {
        
        unitsOneEthCanBuy = _price;
    }
    
    function() external payable{
        require(unitsOneEthCanBuy != 0);
        uint256 amount = (msg.value * unitsOneEthCanBuy)/(10 ** uint256(18));
        balanceOf[owner] -= amount;
        balanceOf[msg.sender] += amount;
        emit Transfer(owner,msg.sender,amount);
           }
    
    function transfer(address _to,uint256 _value)  public returns(bool success){
        balanceOf[_to] += _value;
        balanceOf[msg.sender] -= _value;
        emit Transfer(msg.sender,_to,_value);
        return true;
        
    }
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
            if (balanceOf[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balanceOf[_to] += _value;
            balanceOf[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
     function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
     function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    

    
    function safeWithdraw() public onlyowner {
        address myAddress = address(this);
        uint256 someEth = myAddress.balance;
        msg.sender.transfer(someEth);
        emit Transfer(myAddress,msg.sender,someEth);
        
    }
    
        function mintToken(address target, uint256 mintedAmount) onlyowner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), owner, mintedAmount);
        emit Transfer(owner, target, mintedAmount);
    }
            function burnToken(address target, uint256 burnedAmount) onlyowner public {
        balanceOf[target] -= burnedAmount;
        totalSupply -= burnedAmount;
        emit Transfer(target,address(0), burnedAmount);
        
    }
    
    function addSupply(uint256 _addTotalSupply) public onlyowner {
        totalSupply += _addTotalSupply;
        balanceOf[owner] += _addTotalSupply;
    }
}
