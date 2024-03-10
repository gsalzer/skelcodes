pragma solidity ^0.7.1;

import './SafeMath.sol';
import './Context.sol';

interface IERC20Token {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    /** 
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account, uint amount) external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

abstract contract ERC20Token is IERC20Token, Context {
    using SafeMath for uint;
    
    mapping (address => mapping (address => uint)) internal _allowances;
    mapping (address => uint) internal _balances;
    uint internal _totalSupply;
    
    string public name;
    string public symbol;
    uint public decimals;
    
    function totalSupply() external view override virtual returns (uint){
        return _totalSupply;
    }
    
    function balanceOf(address account) external override virtual view returns (uint){
        return _balances[account];
    }
    
    function transfer(address _to, uint _value) public override virtual contractActive returns(bool){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public virtual contractActive override returns(bool) {
        return _transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint value) public virtual override returns(bool) {
        return _approve(_msgSender(), spender, value);
    }

    function allowance(address owner, address spender) public virtual view override returns (uint) {
        return _allowance(owner, spender);
    }

    function burn(address account, uint amount) external virtual override onlyOwner {
        _burn(account, amount);
    }
    
    /**
     * @dev Withdraw ERC-20 token of this contract
     */ 
    function withdrawToken(address tokenAddress) external onlyOwner contractActive{
        require(tokenAddress != address(0), "Contract address is zero address");
        require(tokenAddress != address(this), "Can not transfer self token");
        
        IERC20Token tokenContract = IERC20Token(tokenAddress);
        uint tokenBalance = tokenContract.balanceOf(address(this));
        require(tokenBalance > 0, "Balance is zero");
        
        tokenContract.transfer(owner, tokenBalance);
    }
    
    function _transfer(address sender, address recipient, uint amount) internal {
        require(amount > 0, "Transfer amount should be greater than zero");
        require(_balances[sender] >= amount);
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _transferFrom(address sender, address recipient, uint amount) internal returns(bool) {
        require(_allowance(sender, _msgSender()) >= amount, "Allowance is not enough");
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowance(sender, _msgSender()).sub(amount));
        return true;
    }
    
    function _approve(address owner, address spender, uint value) internal returns (bool){
        require(value >= 0,"Approval value can not be negative");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
        return true;
    }
    
    function _allowance(address owner, address spender) internal view returns (uint) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint amount) internal virtual returns(bool){
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);

        return true;
    }
}

// SPDX-License-Identifier: MIT
