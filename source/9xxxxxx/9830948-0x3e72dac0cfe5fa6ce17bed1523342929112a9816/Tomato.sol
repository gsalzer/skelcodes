pragma solidity ^ 0.4.19;

 

 

contract Ownable {

    address public owner;

    function Ownable() public {

        owner = msg.sender;

    }

 

    function _msgSender() internal view returns (address)

    {

        return msg.sender;

    }

    

    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }

    

}

 

contract SafeMath {

  function safeMul(uint256 a, uint256 b) internal returns (uint256) {

    uint256 c = a * b;

    assert(a == 0 || c / a == b);

    return c;

  }

 

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {

    assert(b > 0);

    uint256 c = a / b;

    assert(a == b * c + a % b);

    return c;

  }

 

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {

    assert(b <= a);

    return a - b;

  }

 

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {

    uint256 c = a + b;

    assert(c>=a && c>=b);

    return c;

  }

 

  function assert(bool assertion) internal {

    if (!assertion) {

      throw;

    }

  }

}

 

contract Tomato is Ownable, SafeMath {

   

    /* Public variables of the token */

    string public name = 'SToTal Tomato Stable Coin Cash';

    string public symbol = 'STTsch';

    uint8 public decimals = 8; //8//18

    uint256 public totalSupply =(2999999999  * (10 ** uint256(decimals))); //(3000000 * (10 ** uint(decimals))-1); 

    uint public TotalHoldersAmount;

    

    /*Lock transfer from all accounts */

    bool private Lock = false;

    bool public CanChange=true;

    

    

    address public Admin;

    address public AddressForReturn;

    

    address[] Accounts;

    /* This creates an array with all balances */

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

   /*Individual Lock*/

    mapping(address => bool) public AccountIsLock;

    /*Allow transfer for ICO, Admin accounts if IsLock==true*/

    mapping(address => bool) public AccountIsNotLock;

    

   /*Allow transfer tokens only to ReturnWallet*/

    mapping(address => bool) public AccountIsNotLockForReturn;

    mapping(address => uint) public AccountIsLockByDate;

    

    mapping (address => bool) public isHolder;

    mapping (address => bool) public isArrAccountIsLock;

    mapping (address => bool) public isArrAccountIsNotLock;

    mapping (address => bool) public isArrAccountIsNotLockForReturn;

    mapping (address => bool) public isArrAccountIsLockByDate;

    

    

    address [] public Arrholders;

    address [] public ArrAccountIsLock;

    address [] public ArrAccountIsNotLock;

    address [] public ArrAccountIsNotLockForReturn;

    address [] public ArrAccountIsLockByDate;

   

    /* This generates a public event on the blockchain that will notify clients */

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    event StartBurn(address indexed from, uint256 value);

    event StartAllLock(address indexed account);

    event StartAllUnLock(address indexed account);

    event StartUseLock(address indexed account,bool re);

    event StartUseUnLock(address indexed account,bool re);

    event StartAdmin(address indexed account);

   

    

    

    //event UnAdmin(address indexed account);

 

    modifier IsNotLock{

      require(((!Lock&&AccountIsLock[msg.sender]!=true)||((Lock)&&AccountIsNotLock[msg.sender]==true))&&now>AccountIsLockByDate[msg.sender]);

      _;

     }

     

     modifier isCanChange{

      require((msg.sender==owner||msg.sender==Admin)&&CanChange==true);

      _;

     }

     modifier whenNotPaused(){

         require(!Lock);

         _;

     }

     

    /* Initializes contract with initial supply tokens to the creator of the contract */

   

  function Tomato() public {

        balanceOf[msg.sender] = totalSupply;

        Arrholders[Arrholders.length++]=msg.sender;

        Admin=msg.sender;

    }

    

     function setAdmin(address _address) public onlyOwner{

        require(CanChange);

        Admin=_address;

        StartAdmin(Admin);

    }

 

    modifier whenNotLock(){

        require(!Lock);

        _;

    }

    

    modifier whenLock() {

        require(Lock);

        _;

    }

    

    function lock() isCanChange whenNotLock{

        Lock = true;

        StartAllLock(_msgSender()); 

    }

    function unlock() isCanChange whenLock{

        Lock = false;

        StartAllUnLock(_msgSender()); 

    }

    

    function setCanChange(bool _canChange)public onlyOwner{

      require(CanChange);

      CanChange=_canChange;

    }

 

    function UseIsLock(address _address)public onlyOwner{

    bool _IsLock = true;

     AccountIsLock[_address]=_IsLock;

     if (isArrAccountIsLock[_address] != true) {

        ArrAccountIsLock[ArrAccountIsLock.length++] = _address;

        isArrAccountIsLock[_address] = true;

    }if(_IsLock == true){

    StartUseLock(_address,_IsLock);

        }

    }

    

    function UseUnLock(address _address)public onlyOwner{

        bool _IsLock = false;

     AccountIsLock[_address]=_IsLock;

     if (isArrAccountIsLock[_address] != true) {

        ArrAccountIsLock[ArrAccountIsLock.length++] = _address;

        isArrAccountIsLock[_address] = true;

    }

    if(_IsLock == false){

    StartUseUnLock(_address,_IsLock);

        }

    }

    

    function setAccountIsNotLock(address _address, bool _IsLock)public onlyOwner{

     AccountIsNotLock[_address]=_IsLock;

     if (isArrAccountIsNotLock[_address] != true) {

        ArrAccountIsNotLock[ArrAccountIsNotLock.length++] = _address;

        isArrAccountIsNotLock[_address] = true;

    }

 

    }

    

    function setAccountIsNotLockForReturn(address _address, bool _IsLock)public onlyOwner{

     AccountIsNotLockForReturn[_address]=_IsLock;

      if (isArrAccountIsNotLockForReturn[_address] != true) {

        ArrAccountIsNotLockForReturn[ArrAccountIsNotLockForReturn.length++] = _address;

        isArrAccountIsNotLockForReturn[_address] = true;

    }

    }

    

    function TimeLock(address _address, uint _Date)public onlyOwner{

    

        require (!isArrAccountIsLockByDate[_address]);

        AccountIsLockByDate[_address]=_Date;

        ArrAccountIsLockByDate[ArrAccountIsLockByDate.length++] = _address;

        isArrAccountIsLockByDate[_address] = true;

    

    }

    

    /* Send coins */

    function transfer(address _to, uint256 _value) public  {

        require(((!Lock&&AccountIsLock[msg.sender]!=true)||((Lock)&&AccountIsNotLock[msg.sender]==true)||(AccountIsNotLockForReturn[msg.sender]==true&&_to==AddressForReturn))&&now>AccountIsLockByDate[msg.sender]);

        require(balanceOf[msg.sender] >= _value); // Check if the sender has enough

        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows

        balanceOf[msg.sender] -= _value; // Subtract from the sender

        balanceOf[_to] += _value; // Add the same to the recipient

        Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place

        if (isHolder[_to] != true) {

        Arrholders[Arrholders.length++] = _to;

        isHolder[_to] = true;

    }}

    

  

 

    /* Allow another contract to spend some tokens in your behalf */

    function approve(address _spender, uint256 _value)public

    returns(bool success) {

        allowance[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;

    }

 

   

 

    /* A contract attempts to get the coins */

    function transferFrom(address _from, address _to, uint256 _value)public IsNotLock returns(bool success)  {

        require(((!Lock&&AccountIsLock[_from]!=true)||((Lock)&&AccountIsNotLock[_from]==true))&&now>AccountIsLockByDate[_from]);

        require (balanceOf[_from] >= _value) ; // Check if the sender has enough

        require (balanceOf[_to] + _value >= balanceOf[_to]) ; // Check for overflows

        require (_value <= allowance[_from][msg.sender]) ; // Check allowance

        balanceOf[_from] -= _value; // Subtract from the sender

        balanceOf[_to] += _value; // Add the same to the recipient

        allowance[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);

        if (isHolder[_to] != true) {

        Arrholders[Arrholders.length++] = _to;

        isHolder[_to] = true;

        }

        return true;

    }

 

 /* @param _value the amount of money to burn*/

 function burn(uint256 _value) onlyOwner returns (bool success) {

        require(msg.sender != address(0));

        if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough

		if (_value <= 0) throw; 

        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender

        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply

        Transfer(msg.sender,address(0),_value);

        StartBurn(msg.sender, _value);

        return true;

    }

    

    function GetHoldersCount () public view returns (uint _HoldersCount){

  

         return (Arrholders.length-1);

    }

    

    function GetAccountIsLockCount () public view returns (uint _Count){

  

         return (ArrAccountIsLock.length);

    }

    

    function GetAccountIsNotLockForReturnCount () public view returns (uint _Count){

  

         return (ArrAccountIsNotLockForReturn.length);

    }

    

    function GetAccountIsNotLockCount () public view returns (uint _Count){

  

         return (ArrAccountIsNotLock.length);

    }

    

     function GetAccountIsLockByDateCount () public view returns (uint _Count){

  

         return (ArrAccountIsLockByDate.length);

    }

     

     function SetAddressForReturn (address _address) public onlyOwner  returns (bool success ){

         AddressForReturn=_address;

         return true;

    }

 

 

    

    /* This unnamed function is called whenever someone tries to send ether to it */

   function () public payable {

         revert();

    }

}
