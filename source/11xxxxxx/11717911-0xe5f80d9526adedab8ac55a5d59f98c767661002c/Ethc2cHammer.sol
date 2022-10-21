// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Ethc2cHammer is Ownable, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address[] public minters;

    event Mint(address indexed to, uint256 amount);

    constructor () {
        _totalSupply = 10000 * 1e18;
        _balances[msg.sender] = _totalSupply;
        _name = "Ethc2c Hammer Token";
        _symbol = "HAMMER";
        _decimals = 18;
    }

    function isMinter(address _a) 
        public 
        view 
        returns(bool)
    {
        for(uint i = 0; i < minters.length; i ++){
            if(minters[i] == _a){
                return true;
            }
        }
        return false;
    }

    function addMinter(address _minter) 
        public 
        onlyOwner
        returns(bool)
    {
        minters.push(_minter);
        return true;
    }

    function delMinter(address _minter)
        public
        onlyOwner
        returns(bool)
    {
        for(uint i = 0; i < minters.length; i ++ )
        {
            if(minters[i] == _minter)
            {
                delete minters[i];
                return true;
            }
        }
        return false;
    }

    function getMintersLength() 
        public 
        view 
        returns(uint256)
    {
        return minters.length;
    }

    function mint(address _to, uint256 _amount)
        public
        override
    {
        require(isMinter(msg.sender));
        _mint(_to, _amount);
        emit Mint(_to, _amount);
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

   
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

   
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

   
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

  
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

  
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

   
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
}
