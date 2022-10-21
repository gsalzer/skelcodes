//////////////////////////////////////////////////
//SYNLEV BULL CONTRACT V 1.0.0
//////////////////////////

//THIS IS STANDARD OPENZEPLIN ERC-20 CONTRACT WITH BURN/MINT RESTRICTED TO VAULT
//CONTRACT

pragma solidity >= 0.6.4;

import './ownable.sol';
import './SafeMath.sol';
import './IERC20.sol';

contract bull is IERC20, Owned {
  using SafeMath for uint256;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor() public {
    symbol = "BULL";
    name = "3xBULLETH/USD";
    decimals = 18;
    vault = 0xAae6ea9b2884bf263eDf6e61fCdCa2EA8D807008;
  }

  modifier onlyVault {
    require(msg.sender == vault);
    _;
  }

  address public vault;


  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string public name;
  string public symbol;
  uint256 public decimals;

  //allows admin to withdraw other ERC-20 tokens from the contract.
  function adminwithdrawal(IERC20 token, uint256 amount) public onlyOwner() {
    IERC20 thisToken = IERC20(address(this));
    require(token != thisToken);
    token.transfer(msg.sender, amount);
  }

  function mint(address account, uint256 amount) public override onlyVault() {
    _mint(account, amount);
  }
  function burn(uint256 amount) public override onlyVault() {
    _burn(msg.sender, amount);
  }

  function totalSupply() public view override returns (uint256) {
      return _totalSupply;
  }
  function balanceOf(address account) public view override returns (uint256) {
      return _balances[account];
  }
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
      _transfer(_msgSender(), recipient, amount);
      return true;
  }
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
      return _allowances[owner][spender];
  }
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
      _approve(_msgSender(), spender, amount);
      return true;
  }
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
      _transfer(sender, recipient, amount);
      _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
      return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
      _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
      return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
      _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
      return true;
  }
  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");

      _beforeTokenTransfer(sender, recipient, amount);

      _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
  }
  function _mint(address account, uint256 amount) internal virtual {
      require(account != address(0), "ERC20: mint to the zero address");

      _beforeTokenTransfer(address(0), account, amount);

      _totalSupply = _totalSupply.add(amount);
      _balances[account] = _balances[account].add(amount);
      emit Transfer(address(0), account, amount);
  }
  function _burn(address account, uint256 amount) internal virtual {
      require(account != address(0), "ERC20: burn from the zero address");

      _beforeTokenTransfer(account, address(0), amount);

      _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
      _totalSupply = _totalSupply.sub(amount);
      emit Transfer(account, address(0), amount);
  }
  function _approve(address owner, address spender, uint256 amount) internal virtual {
      require(owner != address(0), "ERC20: approve from the zero address");
      require(spender != address(0), "ERC20: approve to the zero address");

      _allowances[owner][spender] = amount;
      emit Approval(owner, spender, amount);
  }
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

