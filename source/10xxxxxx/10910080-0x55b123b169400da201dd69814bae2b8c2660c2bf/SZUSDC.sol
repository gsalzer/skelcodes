pragma solidity 0.5.17;


contract Ownable {


  address newOwner;
  mapping (address=>bool) owners;
  address owner;

// all events will be saved as log files
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AddOwner(address newOwner,string name);
  event RemoveOwner(address owner);

   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
  }

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }

  modifier onlyOwners(){
    require(owners[msg.sender] == true || msg.sender == owner);
    _;
  }

  function addOwner(address _newOwner,string memory newOwnerName) public onlyOwners{
    require(owners[_newOwner] == false);
    require(newOwner != msg.sender);
    owners[_newOwner] = true;
    emit AddOwner(_newOwner,newOwnerName);
  }


  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender);  // can't remove your self
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }

  function isOwner(address _owner) public view returns(bool){
    return owners[_owner];
  }

}

contract ERC20 {
	event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);
       
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    

}

contract SZUSDC is Ownable {
    string public name     = "szUSDC";
    string public symbol   = "szUSDC";
    uint8  public decimals = 18;
    string public company  = "ShuttleOne Pte Ltd";
    uint8  public version  = 3;
    uint8  public depositDecimals = 6;
    address public coldWallet;

    event  Approval(address indexed _tokenOwner, address indexed _spender, uint256 _amount);
    event  Transfer(address indexed _from, address indexed _to, uint256 _amount);
    
    event  Deposit(address indexed _from, uint256 _amount);
    event  Withdraw(address indexed _to, uint256 _amount);

    event AddBlackList(address _user);
    event RemoveBalckList(address _user);
    
    mapping (address => uint256)  balance;
    mapping (address => mapping (address => uint256))  allowed;
    mapping (address => bool) public stopControl;
    mapping (address => bool) public blackList;
   
    ERC20  public usdcToken;

    bool public pause;
    
     constructor() public {
         // USDT ARE 6 DIGIT DECIMAL 
         usdcToken = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //USD Coin (USDC)
         coldWallet = 0x186509E7959dda993Cd25fa4bde171b430F66748; // for fee only
         
     }
     
     function withdrawStupidUser(uint256 amount,address _contract,address _to) public onlyOwners{
      require(_contract != address(usdcToken),"Can't Withdraw USDC"); 
      ERC20  stupid = ERC20(_contract);
      stupid.transfer(_to,amount);
    }

     function changeColdWallet(address _newAddr) public onlyOwners returns(bool){
        require(_newAddr != address(0),"Not support Address 0");
        require(_newAddr != coldWallet,"Can't set will same address");
        
        if(balance[coldWallet] > 0)
            intTransfer(coldWallet,_newAddr,balance[coldWallet]);
            
        coldWallet = _newAddr;
        return true;
     }
     
    function deposit(address _from,uint256 amount) public returns (bool) {
            usdcToken.transferFrom(_from,address(this),amount);
            
            amount = amount * (10 ** 12);
            balance[_from] += amount;
            
            emit Deposit(_from,amount);
            emit Transfer(address(0),_from,amount);
            
            return true;
    }

    function withdraw(uint256 _amount) public returns(bool){
        require(balance[msg.sender] >= _amount,"ERROR-out-of-balance-withdraw");
        require(pause == false);
        
        // want to cut decimal > digit 6
        uint256 usdcAmount = _amount / (10**12);        
        _amount = usdcAmount * (10 ** 12);
        
        
        balance[msg.sender] -= _amount;
        
        usdcToken.transfer(msg.sender,usdcAmount);
        emit Withdraw(msg.sender, _amount);
        emit Transfer(msg.sender,address(0),_amount);
        
        return true;
    }
    
    function withdrawInternal(uint256 _amount,address _to) public onlyOwners returns(bool){
        require(stopControl[_to] == false,"This address not allow");
        require(balance[_to] >= _amount,"ERROR-out-of-balance-withdraw");
                // want to cut decimal > digit 6
        uint256 usdcAmount = _amount / (10**12);        
        _amount = usdcAmount * (10 ** 12);
        
        balance[_to] -= _amount;
        
        usdcToken.transfer(_to,usdcAmount);
        emit Withdraw(_to, _amount);
        emit Transfer(_to,address(0),_amount);
        
        return true;
        
    }
    
    function setControlEmergency(address _addr,bool _control) public onlyOwners{
        require(pause == true);
        stopControl[_addr] = _control;
    }
    
    
    function setStopControl(bool _control) public {
        require(pause == false);
        stopControl[msg.sender] = _control;
    }

    function balanceOf(address _addr) public view returns (uint256){
        return balance[_addr]; 
     }

    function totalSupply() public view returns (uint) {
        // bc this is 6 digit totalSupply want to add more digit
        uint256  _total = usdcToken.balanceOf(address(this)) * (10 ** 12); 
        return  _total;
    }

     function approve(address _spender, uint256 _amount) public returns (bool){
            allowed[msg.sender][_spender] = _amount;
            emit Approval(msg.sender, _spender, _amount);
            return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256){
          return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(blackList[msg.sender] == false,"This Account are blackList");
        require(balance[msg.sender] >= _amount,"ERROR-out-of-balance-transfer");
        require(_to != address(0),"ERROR-transfer-addr-0");
       

        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
        emit Transfer(msg.sender,_to,_amount);
        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool)
    {
        require(blackList[_from] == false,"This Account are blackList");
        require(balance[_from] >= _amount,"ERROR-transFrom-out-of");
        require(allowed[_from][msg.sender] >= _amount,"ERROR-spender-outouf"); 
       

        balance[_from] -= _amount;
        balance[_to] += _amount;
        allowed[_from][msg.sender] -= _amount;
        emit Transfer(_from, _to, _amount);

        return true;
    }
    
    function intTransfer(address _from, address _to, uint256 _amount) public onlyOwners returns(bool){
           require(stopControl[_from] == false,"ERROR-ADDRESS-NOT-ALLOW");
           require(balance[_from] >= _amount,"ERROR-intran-outof");
           require(_to != address(0),"ERROR-intran-addr0");
           
           balance[_from] -= _amount; 
           balance[_to] += _amount;
    
           emit Transfer(_from,_to,_amount);
           return true;
    }
    
    function intTransferWithFee(address _from, address _to, uint256 _value,uint256 _fee) public onlyOwners returns(bool){
            require(stopControl[_from] == false,"ERROR-ADDRESS-NOT-ALLOW");
            require(balance[_from] >= _value);
            require(_to != address(0));
            require(_value > _fee);    
            require(coldWallet != address(0));
        
            balance[_from] -= _value; 
            balance[_to] += _value - _fee;
            balance[coldWallet] += _fee;
    
            emit Transfer(_from,_to,_value);
            emit Transfer(_to,msg.sender,_fee);
    
            return true;
    }
    
    function batchTransfer(address[] memory _from,address[] memory _to,uint256[] memory _amount) public onlyOwners{
         require(_from.length == _amount.length);
         require(_from.length == _to.length);
         
         for(uint256 i = 0; i < _from.length;i ++){
            if(stopControl[_from[i]] == false && balance[_from[i]] >= _amount[i] && _to[i] != address(0) ){
                balance[_from[i]] -= _amount[i]; 
                balance[_to[i]] += _amount[i];
                emit Transfer(_from[i],_to[i],_amount[i]);
            }
         }
    }
    
    function batchTransferWithFee(address[] memory _from,address[] memory _to,uint256[] memory _amount,uint256[] memory _fee) public onlyOwners{
         require(_from.length == _amount.length);
         require(_from.length == _to.length);
         require(coldWallet != address(0));
         
         for(uint256 i = 0; i < _from.length;i ++){
            if(stopControl[_from[i]] == false && balance[_from[i]] >= _amount[i] && _to[i] != address(0) ){
                balance[_from[i]] -= _amount[i]; 
                balance[_to[i]] += _amount[i] - _fee[i];
                balance[coldWallet] += _fee[i];
                
                emit Transfer(_from[i],_to[i],_amount[i] - _fee[i]);
                emit Transfer(_from[i],coldWallet,_fee[i]);
            }
         }
    }
     //================ ADMIN SECURITY FUNCTION ===================
    
    function addBlacklist(address _addr) public onlyOwners{
        blackList[_addr] = true;
        emit AddBlackList(_addr);
    }
    
    function removeBlackList(address _addr) public onlyOwners{
        blackList[_addr] = false;
        emit RemoveBalckList(_addr);
    }
    
    function destroyBlackFund(address _addr) public onlyOwners{
        require(blackList[_addr] == true,"This address not blacklist");
        uint256 amount = balance[_addr];
        
        balance[coldWallet] += amount;
        balance[_addr] = 0;
        
         emit Transfer(_addr,coldWallet,amount);
    }
    
    
    function pauseSystem(bool _set) public onlyOwners{
        pause = _set;
    }


    
}
