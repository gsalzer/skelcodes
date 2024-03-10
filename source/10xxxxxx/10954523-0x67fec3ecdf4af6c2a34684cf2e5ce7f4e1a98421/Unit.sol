pragma solidity ^0.5.8;

interface dividendPoolInterface{
    function AddDivi(address spender,uint256 tansAmount,address recipient, uint256 reciAmount,uint256 burnAmount,uint256 time) external returns(bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20Detailed is Context, IERC20 {
    using SafeMath for uint;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;
    
    uint private _totalSupply;
   
    uint256 public burnRates = 5; //4%
    
    bool public stopBurn = false; // true stop Burn ,false start burn;
    mapping(address => bool) public burnWhitList;
    
    event BurnEVENT(address sender,uint256 transAmount,uint256 fromBalance,address recipient,uint256 recipAmount,uint256 reciBalance,uint256 burnAmount);

    address public dividendPool;//Dividend Pool
    
     constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(dividendPool != address(0),"ERC20: not set dividendPool ");
        
        uint256 burnAmount;
        if(burnWhitList[sender] || burnWhitList[recipient] || stopBurn){
            burnAmount = 0;
        }else{
            burnAmount = amount.mul(burnRates).div(100);
        }
        if(burnAmount == 0){
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);
            
        }else{
            
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount.sub(burnAmount));
            _balances[dividendPool] = _balances[dividendPool].add(burnAmount);
            
            if (dividendPool != address(0) && isContract(dividendPool)){
                dividendPoolInterface(dividendPool).AddDivi(sender,amount,recipient,amount.sub(burnAmount),burnAmount,now);
            }
            
            emit BurnEVENT(sender,amount,_balances[sender],recipient,amount.sub(burnAmount),_balances[recipient],burnAmount);
        }
        
        emit Transfer(sender, recipient, amount);
    }
    
    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        
        emit Transfer(address(0), account, amount);
    }
    
    function _setDividendPoolAddr(address addr) internal{
        dividendPool = addr;
        burnWhitList[dividendPool] = true;
    }
    
    function _setWhiteList(address account,bool isAdd) internal{
        require(account != address(0),"ERC20: whitlist can not be zeor");
        burnWhitList[account] = isAdd;
    }
    
    function _setBurnRate(uint256 rate) internal{
        require(rate<50,"ERC20: burn level must smail 100");
        
        burnRates = rate; 
    }

    function _setStopBurnFlage(bool flage) internal{
        stopBurn = flage;
    }
    
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Unit is ERC20Detailed {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint;
  
 
  address public governance;
  address public manager;
  

  constructor (address ownerAddr) public ERC20Detailed("Unit", "UNIT", 18) {
      governance = msg.sender;
      manager = msg.sender;
      _mint(ownerAddr, 21000000000000000000000);
      
  }
  
  function setGovernance(address _governance) public onlyGovernance{
        require(_governance != address(0));
        governance = _governance;
  }
  
  function  setBurnRate(uint256 rate) public onlyManarger{
      _setBurnRate(rate);
  } 
  
  function setBurnWhiteList(address account,bool isAdd) public onlyManarger{
      _setWhiteList(account,isAdd);
  }
  
  // true is stop burn  false, is burn
  function setBurnStopFlage(bool isStop) public onlyManarger{
      _setStopBurnFlage(isStop);
  }
  
  function setDividendPoolAddr(address diviAddr)  public onlyManarger{
      require(diviAddr != address(0),"unit: manager address can not be zero");
      super._setDividendPoolAddr(diviAddr);
  }
  
  function setManarger(address mAddr) public onlyGovernance{
      require(mAddr != address(0),"Unit: manager address can not be zero");
      manager = mAddr;
      
  }
  
  modifier onlyGovernance{
        require(msg.sender == governance,"only owner");
        _;
    }

    modifier onlyManarger{
        require(msg.sender == manager,"only owner");
        _;
    }
    
}
