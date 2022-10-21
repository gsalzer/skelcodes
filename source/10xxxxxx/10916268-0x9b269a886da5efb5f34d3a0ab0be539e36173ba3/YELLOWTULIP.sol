pragma solidity ^0.5.0;

/*
   ____     __   .-''-.    .---.     .---.       ,-----.    .--.      .--.        ,---------.   ___    _   .---.    .-./`) .-------.  
   \   \   /  /.'_ _   \   | ,_|     | ,_|     .'  .-,  '.  |  |_     |  |        \          \.'   |  | |  | ,_|    \ .-.')\  _(`)_ \ 
    \  _. /  '/ ( ` )   ',-./  )   ,-./  )    / ,-.|  \ _ \ | _( )_   |  |         `--.  ,---'|   .'  | |,-./  )    / `-' \| (_ o._)| 
     _( )_ .'. (_ o _)  |\  '_ '`) \  '_ '`) ;  \  '_ /  | :|(_ o _)  |  |            |   \   .'  '_  | |\  '_ '`)   `-'`"`|  (_,_) / 
 ___(_ o _)' |  (_,_)___| > (_)  )  > (_)  ) |  _`,/ \ _/  || (_,_) \ |  |            :_ _:   '   ( \.-.| > (_)  )   .---. |   '-.-'  
|   |(_,_)'  '  \   .---.(  .  .-' (  .  .-' : (  '\_/ \   ;|  |/    \|  |            (_I_)   ' (`. _` /|(  .  .-'   |   | |   |      
|   `-'  /    \  `-'    / `-'`-'|___`-'`-'|___\ `"/  \  ) / |  '  /\  `  |           (_(=)_)  | (_ (_) _) `-'`-'|___ |   | |   |      
 \      /      \       /   |        \|        \'. \_/``".'  |    /  \    |            (_I_)    \ /  . \ /  |        \|   | /   )      
  `-..-'        `'-..-'    `--------``--------`  '-----'    `---'    `---`            '---'     ``-'`-''   `--------`'---' `---'      
                                                                                                                                      
The tulip reached extraordinarily high levels in February 1637....
/*


/*
 * @title: YellowTulip
 * 2% burn to grow value.
 * We are just trying to grow in value.
 */


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

  uint8 public _Tokendecimals;
  string public _Tokenname;
  string public _Tokensymbol;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
   
    _Tokendecimals = decimals;
    _Tokenname = name;
    _Tokensymbol = symbol;
    
  }

  function name() public view returns(string memory) {
    return _Tokenname;
  }

  function symbol() public view returns(string memory) {
    return _Tokensymbol;
  }

  function decimals() public view returns(uint8) {
    return _Tokendecimals;
  }
}

contract YELLOWTULIP is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) public _YELLOWTULIPTokenBalances;
  mapping (address => mapping (address => uint256)) public _allowed;
  string constant tokenName = "YELLOWTULIP";
  string constant tokenSymbol = "YTLP";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 1637000000000000000000;


  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _YELLOWTULIPTokenBalances[owner];
  }


  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _YELLOWTULIPTokenBalances[msg.sender]);
    require(to != address(0));

    uint256 YELLOWTULIPTokenDecay = value.div(200);
    uint256 tokensToTransfer = value.sub(YELLOWTULIPTokenDecay);

    _YELLOWTULIPTokenBalances[msg.sender] = _YELLOWTULIPTokenBalances[msg.sender].sub(value);
    _YELLOWTULIPTokenBalances[to] = _YELLOWTULIPTokenBalances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(YELLOWTULIPTokenDecay);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), YELLOWTULIPTokenDecay);
    return true;
  }
  

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }


  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _YELLOWTULIPTokenBalances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _YELLOWTULIPTokenBalances[from] = _YELLOWTULIPTokenBalances[from].sub(value);

    uint256 YELLOWTULIPTokenDecay = value.div(100);
    uint256 tokensToTransfer = value.sub(YELLOWTULIPTokenDecay);

    _YELLOWTULIPTokenBalances[to] = _YELLOWTULIPTokenBalances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(YELLOWTULIPTokenDecay);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), YELLOWTULIPTokenDecay);

    return true;
  }
  
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _YELLOWTULIPTokenBalances[account] = _YELLOWTULIPTokenBalances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _YELLOWTULIPTokenBalances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _YELLOWTULIPTokenBalances[account] = _YELLOWTULIPTokenBalances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}
