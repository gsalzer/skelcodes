pragma solidity ^ 0.5.0;

contract Ownerable {
    address public owner;
    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract homihelp is Ownerable{
    /* Public variables of the token */
    string public name = 'HOMIHELP';
    string public symbol = 'HOMI';
    uint8 public decimals = 6;
    uint256 public totalSupply = 100000000 * (10 ** uint256(decimals));
    uint public TotalHoldersAmount;
    /*Freeze transfer from all accounts */
    bool public Frozen=true;
    bool public CanChange=true;
    address public Admin;
    address public AddressForReturn;
    address[] Accounts;
    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
   /*Individual Freeze*/
    mapping(address => bool) public AccountIsFrozen;
    /*Allow transfer for Admin accounts if IsFrozen==true*/
    mapping(address => bool) public AccountIsNotFrozen;
   /*Allow transfer tokens only to ReturnWallet*/
    mapping(address => bool) public AccountIsNotFrozenForReturn;
    mapping(address => uint) public AccountIsFrozenByDate;
    
    mapping (address => bool) public isHolder;
    mapping (address => bool) public isArrAccountIsFrozen;
    mapping (address => bool) public isArrAccountIsNotFrozen;
    mapping (address => bool) public isArrAccountIsNotFrozenForReturn;
    mapping (address => bool) public isArrAccountIsFrozenByDate;
    address [] public Arrholders;
    address [] public ArrAccountIsFrozen;
    address [] public ArrAccountIsNotFrozen;
    address [] public ArrAccountIsNotFrozenForReturn;
    address [] public ArrAccountIsFrozenByDate;
   
    
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    modifier IsNotFrozen{
      require(((!Frozen&&AccountIsFrozen[msg.sender]!=true)||((Frozen)&&AccountIsNotFrozen[msg.sender]==true))&&now>AccountIsFrozenByDate[msg.sender]);
      _;
     }
     
     modifier isCanChange{
      require((msg.sender==owner||msg.sender==Admin)&&CanChange==true);
      _;
     }
     
     
     
     
    /* Initializes contract with initial supply tokens to the creator of the contract */
   
  function HOMIHELP() public {
        balanceOf[msg.sender] = totalSupply;
        Arrholders[Arrholders.length++]=msg.sender;
        Admin=msg.sender;
    }
    
     function setAdmin(address _address) public onlyOwner{
        require(CanChange);
        Admin=_address;
    }
    
   function setFrozen(bool _Frozen)public onlyOwner{
      require(CanChange);
      Frozen=_Frozen;
    }
    
    function setCanChange(bool _canChange)public onlyOwner{
      require(CanChange);
      CanChange=_canChange;
    }
    
    function setAccountIsFrozen(address _address, bool _IsFrozen)public isCanChange{
     AccountIsFrozen[_address]=_IsFrozen;
     if (isArrAccountIsFrozen[_address] != true) {
        ArrAccountIsFrozen[ArrAccountIsFrozen.length++] = _address;
        isArrAccountIsFrozen[_address] = true;
    }
    }
    
    function setAccountIsNotFrozen(address _address, bool _IsFrozen)public isCanChange{
     AccountIsNotFrozen[_address]=_IsFrozen;
     if (isArrAccountIsNotFrozen[_address] != true) {
        ArrAccountIsNotFrozen[ArrAccountIsNotFrozen.length++] = _address;
        isArrAccountIsNotFrozen[_address] = true;
    }
    }
    
    function setAccountIsNotFrozenForReturn(address _address, bool _IsFrozen)public isCanChange{
     AccountIsNotFrozenForReturn[_address]=_IsFrozen;
      if (isArrAccountIsNotFrozenForReturn[_address] != true) {
        ArrAccountIsNotFrozenForReturn[ArrAccountIsNotFrozenForReturn.length++] = _address;
        isArrAccountIsNotFrozenForReturn[_address] = true;
    }
    }
    
    function setAccountIsFrozenByDate(address _address, uint _Date)public isCanChange{
    
        require (!isArrAccountIsFrozenByDate[_address]);
        AccountIsFrozenByDate[_address]=_Date;
        ArrAccountIsFrozenByDate[ArrAccountIsFrozenByDate.length++] = _address;
        isArrAccountIsFrozenByDate[_address] = true;
    
    }
    
    /* Send coins */
    function transfer(address _to, uint256 _value) public  {
        require(((!Frozen&&AccountIsFrozen[msg.sender]!=true)||((Frozen)&&AccountIsNotFrozen[msg.sender]==true)||(AccountIsNotFrozenForReturn[msg.sender]==true&&_to==AddressForReturn))&&now>AccountIsFrozenByDate[msg.sender]);
        require(balanceOf[msg.sender] >= _value); // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
        if (isHolder[_to] != true) {
        Arrholders[Arrholders.length++] = _to;
        isHolder[_to] = true;
    }}
    
  
 
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)public
    returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

   

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value)public IsNotFrozen returns(bool success)  {
        require(((!Frozen&&AccountIsFrozen[_from]!=true)||((Frozen)&&AccountIsNotFrozen[_from]==true))&&now>AccountIsFrozenByDate[_from]);
        require (balanceOf[_from] >= _value) ; // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]) ; // Check for overflows
        require (_value <= allowance[_from][msg.sender]) ; // Check allowance
        balanceOf[_from] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        if (isHolder[_to] != true) {
        Arrholders[Arrholders.length++] = _to;
        isHolder[_to] = true;
        }
        return true;
    }

    
    function GetHoldersCount () public view returns (uint _HoldersCount){
  
         return (Arrholders.length-1);
    }
    
    function GetAccountIsFrozenCount () public view returns (uint _Count){
  
         return (ArrAccountIsFrozen.length);
    }
    
    function GetAccountIsNotFrozenForReturnCount () public view returns (uint _Count){
  
         return (ArrAccountIsNotFrozenForReturn.length);
    }
    
    function GetAccountIsNotFrozenCount () public view returns (uint _Count){
  
         return (ArrAccountIsNotFrozen.length);
    }
    
     function GetAccountIsFrozenByDateCount () public view returns (uint _Count){
  
         return (ArrAccountIsFrozenByDate.length);
    }
     
     function SetAddressForReturn (address _address) public isCanChange  returns (bool success ){
         AddressForReturn=_address;
         return true;
    }
    
    function setSymbol(string memory _symbol) public onlyOwner {
        require(CanChange);
        symbol = _symbol;
    }
    
    function setName(string memory _name) public onlyOwner {
        require(CanChange);
        name = _name;
    }
    
    
    /* This unnamed function is called whenever someone tries to send ether to it */
   function() external payable {
         revert();
    }
}
