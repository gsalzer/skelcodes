/*
Bringing all the good vibes code


*/

pragma solidity ^0.5.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract VibesFinance is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

//tax wallet
  address devWallet = 0x3bd644653eBc0F0f95253d82f9a536bB1e9BF7e2;
  
  //dev wallet so I can transfer dev to burn address after
  address devWallet2 = 0x1BFEb45AA356146a25E9E7658E4DBc1D7e54B321;
  address[] VibesWallets = [devWallet, devWallet, devWallet];
  string constant tokenName = "Vibes.Finance";
  string constant tokenSymbol = "VIBES";
  uint8  constant tokenDecimals = 18;
  uint256 public _totalSupply = 10000000000000000000000;
  uint256 public basePercent = 5;
  address uniswapAddress;
  bool public VibesMode = false;
  bool public LimitMode = false;
  bool public DevMode = true;

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function amountToTake(uint256 value) public view returns (uint256)  {
    uint256 amountLost = value.mul(basePercent).div(100);
    return amountLost;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    
   if (DevMode) {
        
                   require(
                       msg.sender==devWallet2,
    "Dev Mode is on so that bots don't take over while I list"
);
        
    }
    
    
      if (LimitMode) {
        
                   require(
                       value<=200000000000000000000,
    "Amount not authorized, please buy less than 200"
);
        
    }

    _balances[msg.sender] = _balances[msg.sender].sub(value);

    if (VibesMode){
        
    if(uniswapAddress == msg.sender){
        uint256 totalVibes = amountToTake(value);
        uint256 tokensToVibes = totalVibes.div(5).mul(2);
        uint256 tokensToDev = totalVibes.div(5);
        uint256 tokensToTransfer = value.sub(totalVibes);

        _balances[to] = _balances[to].add(tokensToTransfer);
        _balances[VibesWallets[0]] = _balances[VibesWallets[0]].add(tokensToVibes);
        _balances[VibesWallets[1]] = _balances[VibesWallets[1]].add(tokensToVibes);
        _balances[devWallet] = _balances[devWallet].add(tokensToDev);
        
        emit Transfer(msg.sender, to, tokensToTransfer);
        emit Transfer(msg.sender, VibesWallets[1], tokensToVibes);
        emit Transfer(msg.sender, VibesWallets[0], tokensToVibes);
        emit Transfer(msg.sender, devWallet, tokensToDev);
        }
        
        else {
        address previousSender = VibesWallets[0];
        VibesWallets[0] = VibesWallets[1];
        VibesWallets[1] = msg.sender;
        uint256 totalVibes = amountToTake(value);
        uint256 tokensToVibes = totalVibes.div(5).mul(2);
        uint256 tokensToDev = totalVibes.div(5);
        uint256 tokensToTransfer = value.sub(totalVibes);

        _balances[to] = _balances[to].add(tokensToTransfer);
        _balances[previousSender] = _balances[previousSender].add(tokensToVibes);
        _balances[VibesWallets[0]] = _balances[VibesWallets[0]].add(tokensToVibes);
        _balances[devWallet] = _balances[devWallet].add(tokensToDev);
        
        
        emit Transfer(msg.sender, to, tokensToTransfer);
        emit Transfer(msg.sender, previousSender, tokensToVibes);
        emit Transfer(msg.sender, VibesWallets[0], tokensToVibes);
        emit Transfer(msg.sender, devWallet, tokensToDev);

    }
    }
    else{
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
    }

    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
    
    if (DevMode) {
        
                   require(
                       msg.sender==devWallet2,
    "Dev Mode is on so that bots don't take over while I list"
);
        
    }
    
     if (LimitMode) {
        
                   require(
                       value<=200000000000000000000,
    "Amount not authorized, please buy less than 200"
);
    }

    _balances[from] = _balances[from].sub(value);

    if (VibesMode){
        
        if(uniswapAddress == msg.sender){
        uint256 totalVibes = amountToTake(value);
        uint256 tokensToVibes = totalVibes.div(5).mul(2);
        uint256 tokensToDev = totalVibes.div(5);
        uint256 tokensToTransfer = value.sub(totalVibes);

        _balances[to] = _balances[to].add(tokensToTransfer);
        _balances[VibesWallets[0]] = _balances[VibesWallets[0]].add(tokensToVibes);
        _balances[VibesWallets[1]] = _balances[VibesWallets[1]].add(tokensToVibes);
        _balances[devWallet] = _balances[devWallet].add(tokensToDev);
        emit Transfer(from, to, tokensToTransfer);
        emit Transfer(from, VibesWallets[1], tokensToVibes);
        emit Transfer(from, VibesWallets[0], tokensToVibes);
        emit Transfer(from, devWallet, tokensToDev);
        }
        
        else {
        address previousSender = VibesWallets[0];
        VibesWallets[0] = VibesWallets[1];
        VibesWallets[1] = to;
        uint256 totalVibes = amountToTake(value);
        uint256 tokensToVibes = totalVibes.div(5).mul(2);
        uint256 tokensToDev = totalVibes.div(5);
        uint256 tokensToTransfer = value.sub(totalVibes);

        _balances[to] = _balances[to].add(tokensToTransfer);
        _balances[previousSender] = _balances[previousSender].add(tokensToVibes);
        _balances[VibesWallets[0]] = _balances[VibesWallets[0]].add(tokensToVibes);
        _balances[devWallet] = _balances[devWallet].add(tokensToDev);
   

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, tokensToTransfer);
        emit Transfer(from, VibesWallets[1], tokensToVibes);
        emit Transfer(from, VibesWallets[0], tokensToVibes);
        emit Transfer(from, devWallet, tokensToDev);

    }
    }
    else {
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)  public {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }


  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }

  function enableVibesMode() public {
    require (msg.sender == devWallet2);
    VibesMode = true;
  }
 
  
    function disableVibesMode() public {
    require (msg.sender == devWallet2);
    VibesMode = false;
  }
  
    function disableLimitMode() public {
    require (msg.sender == devWallet2);
    LimitMode = false;
  }
  
      function enableLimitMode() public {
    require (msg.sender == devWallet2);
    LimitMode = true;
  }
  
     function enableDevMode() public {
    require (msg.sender == devWallet2);
    DevMode = true;
  }
  
     function disableDevMode() public {
    require (msg.sender == devWallet2);
    DevMode = false;
  }
  
      function setUniAddress(address _lpToken) public {
    require (msg.sender == devWallet2);
    uniswapAddress = _lpToken;
  }
  
  function ChangeDev2(address _lpToken) public {
    require (msg.sender == devWallet2);
    devWallet2 = _lpToken;
  }
  
}
