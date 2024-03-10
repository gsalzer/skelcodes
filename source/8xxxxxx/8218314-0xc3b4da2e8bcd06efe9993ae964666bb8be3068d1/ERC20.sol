pragma solidity ^0.5.0;

import './ERC20Interface.sol';
import './SafeMath.sol';

/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 */
contract ERC20 is IERC20 {
    
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;
    
    mapping (address => uint256) private _freezeOf;
    
    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param tokenOwner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return _balances[tokenOwner];
    }
    
    /**
     * @dev Gets the balance of the specified freeze address.
     * @param tokenOwner The address to query the balance of.
     * @return A uint256 representing the amount owned by the freeze address.
     */
    function freezeOf(address tokenOwner) public view returns (uint256) {
        return _freezeOf[tokenOwner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param tokenOwner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return _allowed[tokenOwner][spender];
    }
    
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool success) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param tokenOwner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address tokenOwner, address spender, uint256 value) internal {
        
		require(tokenOwner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowed[tokenOwner][spender] = value;
		
        emit Approval(tokenOwner, spender, value);
        
    }
    
    /**
     * @dev Transfer token to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        
		require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
		
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        
        emit Transfer(from, to, value);
    }
    
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. 
     * To increment allowed value is better to use this function to avoid 2 calls (and wait until the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool success) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. 
     * To decrement allowed value is better to use this function to avoid 2 calls (and wait until the first transaction is mined)
	 * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool success) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to an account. 
	 * This encapsulates the modification of balances such that the
     * Emits a Transfer event.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
		
		require(account != address(0), "ERC20: mint to the zero address");
		
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
		
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
		
        require(account != address(0), "ERC20: burn from the zero address");
        
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
		
        emit Transfer(account, address(0), value);
    }
    
    function _freeze(uint256 value) internal {
		
        require(_balances[msg.sender] >= value,"ERC20: balance is not enough"); 
        require(value > 0,"ERC20: value must be greater than 0");
		
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _freezeOf[msg.sender] = _freezeOf[msg.sender].add(value);
		
        emit Freeze(msg.sender, value);
    }
    
    function _unfreeze(uint256 value) internal{
		
		require(_freezeOf[msg.sender] >= value,"ERC20: balance is not enough"); 
		require(value > 0,"ERC20: value must be greater than 0");
		
        _freezeOf[msg.sender] = _freezeOf[msg.sender].sub(value); 
		_balances[msg.sender] = _balances[msg.sender].add(value);
		
        emit Unfreeze(msg.sender, value);

    }
    
}
