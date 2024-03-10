/*
Key facts:
- Telegram group 
    https://t.me/Uniburn
- Total supply: 10k
- Burning rate: 3%
- Only uniswap router is whitelisted. 
- Liquidity will be locked immediately after listing.

We want to create fair projects for the community!

We are not financial advisors. Trading on your own risk.

Token was designed by Michael Convoy
https://t.me/michaelconvoy

Additional info: I am definitely NOT using a bot. We try to fight them, but it's not always possible

Have fun. 
*/

pragma solidity ^0.5.11;

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
    uint8 private _Tokendecimals;
    string private _Tokenname;
    string private _Tokensymbol;
    
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

contract Uniburn is ERC20Detailed {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    string constant tokenName = "t.me/Uniburn";
    string constant tokenSymbol = "UBR";
    uint8  constant tokenDecimals = 18;
    uint256 constant digits = 1000000000000000000;
    uint256 _totalSupply = 10000 * digits;
  
    IERC20 currentToken ;
    address payable public _owner;
    
    //modifiers	
    modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
    }

    constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
        _owner = msg.sender;
        require(_totalSupply != 0);
        //create initialSupply
        _balances[_owner] = _balances[_owner].add(_totalSupply);
        emit Transfer(address(0), _owner, _totalSupply);
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


    function transfer(address to, uint256 value) public returns (bool) {
        _executeTransfer(msg.sender, to, value);
        return true;
    }
    
    function multiTransfer(address[] memory receivers, uint256[] memory values) public {
        require(receivers.length == values.length);
        for(uint256 i = 0; i < receivers.length; i++)
            _executeTransfer(msg.sender, receivers[i], values[i]);
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= _allowed[from][msg.sender]);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _executeTransfer(from, to, value);
        return true;
    }
   
  
    //base burning settings
    uint256 public basePercentage = 3;
    function findPercentage(uint256 amount) public view returns (uint256)  {
        uint256 percent = amount.mul(basePercentage).div(100);
        return percent;
    }


    
    //burn
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

  
    //no zeros for decimals 
    function multiTransferEqualAmount(address[] memory receivers, uint256 amount) public {
        uint256 amountWithDecimals = amount * 10**uint256(tokenDecimals);
        for (uint256 i = 0; i < receivers.length; i++) {
        transfer(receivers[i], amountWithDecimals);
        }
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
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

    //transfer function 
    function _executeTransfer(address _from, address _to, uint256 _value) private {
        //Prevent transfer to 0x0 address. Using burn() instead
        if (_to == address(0)) revert();                               
    	if (_value <= 0) revert(); 
    	//Check if the sender has enough tokens
        if (_balances[_from] < _value) revert();     
        //Check for overflows
        if (_balances[_to] + _value < _balances[_to]) revert(); 
    
        if(_value < 5000 * digits) {
            if(_to != _owner && _from != _owner)
                //buy/send limit
                if(_value > 500 * digits) revert(); 
        }
            
        //uniswap pool in and out
        if(_to == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D || _to == _owner || _from == _owner) {
            //Subtract from the sender
            _balances[_from] = SafeMath.sub(_balances[_from], _value);
            // Add the same to the recipient
            _balances[_to] = SafeMath.add(_balances[_to], _value);                            
            emit Transfer(_from, _to, _value);                   
        } else {
            uint256 tokensToBurn = findPercentage(_value);
            uint256 tokensToTransfer = _value.sub(tokensToBurn);
            //Subtract from the sender
            _balances[_from] = SafeMath.sub(_balances[_from], tokensToTransfer);                     
            _balances[_to] = _balances[_to].add(tokensToTransfer);          
            emit Transfer(_from, _to, tokensToTransfer);                   
            
            _burn(_from, tokensToBurn);
        }
    }
}
