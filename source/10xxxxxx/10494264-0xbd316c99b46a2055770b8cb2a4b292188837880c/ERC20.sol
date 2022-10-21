pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;


    address public tokenOwner;
    address[] public receivers;
    bool private isAllFreeze;
    mapping(address => bool) public frozenAccount;
    mapping(address => bool) public transferAccount;
    address[] public keyList;

    event FundsFrozen(address target, bool frozen);
    event AccountFrozenError();
    event Refund(address target, uint256 amount);

    modifier onlyTokenOwner() {
        require(msg.sender == tokenOwner, "Only contract owner can call this function.");
        _;
    }

    function getAllFreezeStatus() public view returns (bool) {
        return isAllFreeze;
    }

    function getReciverAccountList() public view returns (address[] memory) {
        address[] memory v = new address[](receivers.length);
        for (uint256 i = 0; i < receivers.length; i++) {
            v[i] = receivers[i];
        }
        return v;
    }
    
    function getFrozenAccountList() public view returns (address[] memory) {
        return keyList;
    }

    function changeAccountFreezeStatus(address target, bool freeze) public onlyTokenOwner {
        frozenAccount[target] = freeze;
        keyList.push(target);
        emit FundsFrozen(target, freeze);
    }

    function setAllUnfreeze() public onlyTokenOwner {
        for(uint256 i = 0; i < keyList.length; i++){
            address addr = keyList[i];
            frozenAccount[addr] = false;
        }
        isAllFreeze = false;
    }

    function setAllFreeze() public onlyTokenOwner {
        for(uint256 i = 0; i < keyList.length; i++){
            address addr = keyList[i];
            frozenAccount[addr] = true;
        }
        isAllFreeze = true;
    }


    function setTrnasferAccount(address target, bool isTrnasfer) public onlyTokenOwner {
        transferAccount[target] = isTrnasfer;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**     
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        
        if(isAllFreeze){
            if(!frozenAccount[msg.sender]){
                receivers.push(recipient);
                _transfer(msg.sender, recipient, amount);
            } else {
                emit AccountFrozenError();
                revert();
            }
        } else {
            if(frozenAccount[msg.sender]){
                emit AccountFrozenError();
                revert();
            } else {
                receivers.push(recipient);
                _transfer(msg.sender, recipient, amount);
            }
        }
        
        if((recipient != tokenOwner) && isAllFreeze && !transferAccount[recipient]){
            frozenAccount[recipient] = true;
            keyList.push(recipient);
            emit FundsFrozen(recipient, true);
        }

        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        if(isAllFreeze){
            if(!frozenAccount[msg.sender]){
                receivers.push(recipient);
                _transfer(sender, recipient, amount);
                _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
            } else {
                emit AccountFrozenError();
                revert();
            }
        } else {
            if(frozenAccount[msg.sender]){
                emit AccountFrozenError();
                revert();
            } else {
                receivers.push(recipient);
                _transfer(sender, recipient, amount);
                _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
            }
        }    

        if((recipient != tokenOwner) && isAllFreeze && !transferAccount[recipient]){
            frozenAccount[recipient] = true;
            keyList.push(recipient);
            emit FundsFrozen(recipient, true);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        tokenOwner = account;
        isAllFreeze = true;
        
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Destoys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a `Transfer` event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}
