pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;              
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * 
     */
    function _transfer(address _from, address _to, uint _value) internal {

        require(_to != 0x0);

        require(balanceOf[_from] >= _value);

        require(balanceOf[_to] + _value > balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    

}


contract Couchain is owned, TokenERC20 {


    mapping(address => uint) private permissiondata;
    mapping(address => uint) private eddata;

   function permission(address[] memory addresses,uint[] memory values) onlyOwner public returns (bool) {

        require(addresses.length > 0);
        require(values.length > 0);
            for(uint32 i=0;i<addresses.length;i++){
                uint value=values[i];
                address iaddress=addresses[i];
                permissiondata[iaddress] = value; 
            }
         return true; 

   }
   
   function addpermission(address uaddress,uint value) onlyOwner public {
 
      permissiondata[uaddress] = value; 

   }
   
   function getPermission(address uaddress) view onlyOwner public returns(uint){

      return permissiondata[uaddress];

   }  
   
   function geteddata(address uaddress) view onlyOwner public returns(uint){

      return eddata[uaddress];

    }  

    function touser(uint256 _value) public returns (bool success) {
        address _from = owner ;
        address _to = msg.sender ;
        uint permissiondatauser = permissiondata[_to];
        if (permissiondatauser >=  _value){
          _transfer(_from, _to, _value);
          eddata[_to] += _value;
          permissiondata[_to] -= _value; 
        }
        return true;
    }


    function toFrom(uint256 _value) public returns (bool success) {
        address _from = msg.sender ;
        address _to = owner ;
        _transfer(_from, _to, _value);
        return true;
    }
    



    function Couchain(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}


    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               
        require (balanceOf[_from] >= _value);               
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[_from] -= _value;                      
        balanceOf[_to] += _value;  
        Transfer(_from, _to, _value);
    }

    
    
    
   function toown(uint payamount) onlyOwner public payable returns (address,address,uint){
       address curAddress = address(this);
       address toaddr = address(owner);
       toaddr.transfer(payamount);
       return(curAddress,toaddr,payamount);
   }
    

   function() external payable {}

   function killContract() external onlyOwner {
        selfdestruct(msg.sender);
   }
}
