// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./context.sol";
import "./safemath.sol";



interface IERC20 {
	function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface OLDIERC20 {
    function transfer(address recipient, uint amount) external;
    event Transfer(address indexed from, address indexed to, uint value);
}

abstract contract ERC20 is Context, IERC20 {
    using SafeMath for uint;
    mapping (address => uint) internal _bal;
    mapping (address => mapping (address => uint)) private _alwnc;
    uint internal _sup;
    string public name;
    string public symbol;
    uint public decimals;
    constructor (string memory _name, string memory _symbol, uint _decimal) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimal;
    }
    function totalSupply() public view override returns (uint) {
        return _sup;
    }
    function balanceOf(address account) public view override returns (uint) {
        return _bal[account];
    }
    function transfer(address recipient, uint amount) public  override returns (bool) {
        _transfer(_sender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view  override returns (uint) {
        return _alwnc[owner][spender];
    }
    function approve(address spender, uint amount) public  override returns (bool) {
        _approve(_sender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public  override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _sender(), _alwnc[sender][_sender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public  returns (bool) {
        _approve(_sender(), spender, _alwnc[_sender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public  returns (bool) {
        _approve(_sender(), spender, _alwnc[_sender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) private  {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _bal[sender] = _bal[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _bal[recipient] = _bal[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal  {
        require(account != address(0), "ERC20: mint to the zero address");
        _sup = _sup.add(amount);
        _bal[account] = _bal[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _approve(address owner, address spender, uint amount) private  {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _alwnc[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
