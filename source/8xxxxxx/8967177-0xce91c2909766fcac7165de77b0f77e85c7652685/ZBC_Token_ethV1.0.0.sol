pragma solidity >=0.4.23 <0.6.0;

import "./safemath.sol"; // this import is automatically injected by Remix.
import "./AddressUtils.sol";  
 
contract Ownable {

    address public tokenOwner;
    address public tokenSupervisor;
    address public tokenAdmin;
       
    event OwnershipModify(address indexed previousOwner, address indexed newOwner);
    event tokenSupervisorModify(address indexed previousSupervisor, address indexed newSupervisor);
    event tokenAdminModify(address indexed previoustokenAdmin, address indexed newtokenAdmin);

    constructor () public {
        tokenOwner = msg.sender;
        tokenSupervisor = msg.sender;
        tokenAdmin = msg.sender;
    }

    modifier onlyTokenOwner() {
        require(msg.sender == tokenOwner);
        _;
    }
  
    modifier onlyTokenSupervisor() {
        require(msg.sender == tokenSupervisor);
        _;
    }

    modifier onlyTokenAdmin() {
        require(msg.sender == tokenAdmin);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == tokenOwner ||
            msg.sender == tokenSupervisor ||
            msg.sender == tokenAdmin
        );
        _;
    }    

    function modifyOwner(address _newTokenOwner) onlyTokenOwner public  {
      
        require(_newTokenOwner != address(0));       
        tokenOwner = _newTokenOwner;     
        emit OwnershipModify(tokenOwner, _newTokenOwner);       
                  
    }

    function modifySupervisor(address _newSupervisor) onlyTokenOwner public  {
        require(_newSupervisor != address(0));
        tokenSupervisor = _newSupervisor;    
        emit tokenSupervisorModify(tokenSupervisor, _newSupervisor);        
                 
    }
   
    function modifyTokenAdmin(address _newTokenAdmin) onlyTokenOwner public  {
        require(_newTokenAdmin != address(0));        
        tokenAdmin = _newTokenAdmin;     
        emit tokenAdminModify(tokenAdmin, _newTokenAdmin);        
                 
    }     
}

 
contract Pausable is Ownable {

    event EventPause();
    event EventUnpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function setPause() onlyCLevel whenNotPaused public {
        paused = true;
        emit EventPause();
    }

    function setUnpause() onlyCLevel whenPaused public {
        paused = false;
        emit EventUnpause();
    }
}


contract ERC20Basic {

    uint256 public totalSupply;
    
  
    function balanceOf(address who) public view returns (uint256);
    

    function transfer(address toAddr, uint256 value) public payable returns (bool);
    

    event Transfer(address indexed fromAddr, address indexed toAddr, uint256 value);
}

contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender) public view returns (uint256);
    
    function transferFrom(address fromAddr, address toAddr, uint256 value) public payable returns (bool);
    

    function approve(address spender, uint256 value) public returns (bool);
    

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) public balances;


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

//datacontrolcontract
contract StandardToken is ERC20, BasicToken,Ownable {
    

    mapping (address => bool) public frozenAccount;
    mapping (address => mapping (address =>uint256)) internal allowed;


    /* This notifies clients about the amount burnt */
    event BurnTokens(address indexed fromAddr, uint256 value);
	
   /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    

    function transfer(address _toAddr, uint256 _value) public payable returns (bool) {
    
        require(_toAddr != address(0));
        require(!frozenAccount[msg.sender]);           // Check if sender is frozen
        require(!frozenAccount[_toAddr]);              // Check if recipient is frozen
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_toAddr] = balances[_toAddr].add(_value);
        
        emit Transfer(msg.sender, _toAddr, _value);
        return true;
    	  }


  function transferFrom(address _fromAddr, address _toAddr, uint256 _value) onlyCLevel public payable  returns (bool) {
  
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_toAddr != address(0));
        
        require(!frozenAccount[_fromAddr]);           // Check if sender is frozen
        require(!frozenAccount[_toAddr]);              // Check if recipient is frozen
        require(_value <= balances[_fromAddr]);                     
     
        require(_value <= allowed[_fromAddr][msg.sender]);

        balances[_fromAddr] = balances[_fromAddr].sub(_value);
        balances[_toAddr] = balances[_toAddr].add(_value);
        allowed[_fromAddr][msg.sender] = allowed[_fromAddr][msg.sender].sub(_value);
        
        emit Transfer(_fromAddr, _toAddr, _value);
        return true;
    
    }


	function batchTransfer(address[] memory _receivers, uint256 _value) onlyCLevel public payable returns (bool) {
		
		    uint256 cnt = _receivers.length;
		    
		    uint256 amount = _value.mul(cnt); 
		    
		    require(cnt > 0 && cnt <= 20);
		    
		    require(_value > 0 && balances[msg.sender] >= amount);
		    
        require(!frozenAccount[msg.sender]);           // Check if sender is frozen
 
		    balances[msg.sender] = balances[msg.sender].sub(amount);
		    
		    for (uint256 i = 0; i < cnt; i++) {
		        balances[_receivers[i]] = balances[_receivers[i]].add(_value);
		        emit Transfer(msg.sender, _receivers[i], _value);
		    }
		    
		    return true;
		  }
 

    function approve(address _spender, uint256 _value) public returns (bool) {
    
        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //test function 
    function getMsgSender()  public view  returns (address ) {
         return  msg.sender;
        }
        
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function getAccountFreezedInfo(address _owner) public view returns (bool) {
        return frozenAccount[_owner];
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

  function burnTokens(uint256 _burnValue)  onlyTokenOwner public payable  returns (bool success) {
       // Check if the sender has enough
	     require(balances[msg.sender] >= _burnValue);    

	     
       // Subtract from the sender
        balances[msg.sender] = balances[msg.sender].sub(_burnValue);              
       // Updates totalSupply
        totalSupply = totalSupply.sub(_burnValue);                              
        
        emit BurnTokens(msg.sender, _burnValue);
        return true;
    }


        
    function burnTokensFrom(address _fromAddr, uint256 _value) onlyCLevel public payable  returns (bool success) {
        
        require(balances[_fromAddr] >= _value);                // Check if the targeted balance is enough
       
        require(_fromAddr != msg.sender);   
        
        require(allowed[_fromAddr][msg.sender] >=_value);  
        
        allowed[_fromAddr][msg.sender] = allowed[_fromAddr][msg.sender].sub(_value);      
         
        balances[_fromAddr] = balances[_fromAddr].sub(_value);     // Subtract from the targeted balance
       
        totalSupply =totalSupply.sub(_value) ;             // Update totalSupply
        
        emit BurnTokens(_fromAddr, _value);
        return true;
        }
  
    function freezeAccount(address _target, bool _freeze) onlyCLevel public  returns (bool success) {
        
        require(_target != msg.sender);
        
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
        return _freeze;
        }
}

contract PausableToken is StandardToken, Pausable {

    function transfer(address _toAddr, uint256 _value) whenNotPaused public payable returns (bool) {
        return super.transfer(_toAddr, _value);
    }

    function transferFrom(address _fromAddr, address _toAddr, uint256 _value) whenNotPaused public payable returns (bool) {
        return super.transferFrom(_fromAddr, _toAddr, _value);
    }

    function  batchTransfer(address[] memory _receivers, uint256 _value) whenNotPaused public payable returns (bool) {
        return super.batchTransfer(_receivers, _value);
    }


    function approve(address _spender, uint256 _value) whenNotPaused public  returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint256 _addedValue) whenNotPaused public  returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) whenNotPaused public  returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
    
    
  function burnTokens( uint256 _burnValue) whenNotPaused public payable returns (bool success) {
        return super.burnTokens(_burnValue);
    }
    
  function burnTokensFrom(address _fromAddr, uint256 _burnValue) whenNotPaused public payable returns (bool success) {
        return super.burnTokensFrom( _fromAddr,_burnValue);
    }    
    
    //test function 
  function getMsgSender()   public view returns (address ) {
        return super.getMsgSender();
    }   
    
  function freezeAccount(address _target, bool _freeze)  whenNotPaused public  returns (bool success) {
        return super.freezeAccount(_target,_freeze);
    }   
       
}

contract CustomToken is PausableToken {

    string public name;
    string public symbol;
    uint8 public decimals ;
   
    
    // Constants
    string  public constant tokenName = " ZBT game exchange acceptance token,www.zbt.com";
    string  public constant tokenSymbol = "ZBC";
    uint8   public constant tokenDecimals = 6;
    
    uint256 public constant initTokenSUPPLY      = 5000000000 * (10 ** uint256(tokenDecimals));
             
                                        
    constructor () public {

        name = tokenName;

        symbol = tokenSymbol;

        decimals = tokenDecimals;

        totalSupply = initTokenSUPPLY;    
                
        balances[msg.sender] = totalSupply;   

    }    

}

