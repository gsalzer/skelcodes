// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol" ; 

//@title PRDX staking contract interface
interface PRDX_staking {
    function stake(address staker, uint256 amount) external returns (bool success);
}

//@title PRDX prediction market contract interface
interface PRDX_prediction {
    function predict(address user, uint256 amount, uint256 price, uint256 phase) external returns (bool success);
}

//@title PRDX token distribution contract interface
interface PRDX_tokendistr {
    function sell_PRDX(address user, uint256 amount) external returns (bool success); 
}

//@title PRDX Token core contract
//@author Predix Network Team
contract PredixNetwork is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    //contract addresses
    address public staking_addr ; 
    address public prediction_addr ;
    address public tokendistr_addr ; 
    
    //contracts 
    PRDX_staking staking_contract = PRDX_staking(staking_addr) ; 
    PRDX_prediction prediction_contract = PRDX_prediction(prediction_addr) ; 
    PRDX_tokendistr tokendistr_contract = PRDX_tokendistr(tokendistr_addr) ;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () {
        _name = "Predix Network";
        _symbol = "PRDX";
        _decimals = 18;
        _mint(msg.sender, 1.6 * 1e6 * 10**_decimals); 
    }
    
    /**
     * @dev Set staking contract address
     * @param addr Address of staking contract
     *
     */
    function set_staking_address(address addr) public onlyOwner {
        staking_addr = addr ; 
        staking_contract = PRDX_staking(staking_addr) ;
    }
    
    /**
     * @dev Set prediction market contract address
     * @param addr Address of prediction market contract
     *
     */
    function set_prediction_address(address addr) public onlyOwner {
        prediction_addr = addr ; 
        prediction_contract = PRDX_prediction(prediction_addr) ;
    }
    
    
    function set_tokendistr_address(address addr) public onlyOwner {
        tokendistr_addr = addr ; 
        tokendistr_contract = PRDX_tokendistr(tokendistr_addr) ; 
    }
    
    /**
     * @dev Approve prediction market contract to take tokens and make prediction
     * @param   amount Value of prediction paid by user
     *          price Predicted price at phase close
     *          phase Phase for which prediction is made
     * @return success Success of transaction, only false if transaction failed
     */
    function approveAndPredict(uint256 amount, uint256 price, uint256 phase) public returns (bool success) {
        require(balanceOf(msg.sender) >= amount, "Prediction amount exceeds user token balance") ; 
        _approve(msg.sender, prediction_addr, amount) ; 
        
        require(prediction_contract.predict(msg.sender, amount, price, phase)) ; 
        
        return true ; 
    }
    
    /**
     * @dev Approve staking contract to take tokens and start staking
     * @param amount Amount of tokens to be staked
     * @return success Success of transaction, only false if transaction failed
     */
    function approveAndStake(uint256 amount) public returns (bool success) {
        require(balanceOf(msg.sender) >= amount, "Staking amount exceeds user token balance") ;
        _approve(msg.sender, staking_addr, amount) ; 
        
        require(staking_contract.stake(msg.sender, amount)) ; 
        
        return true ; 
    }
    
    /**
     * @dev Approve token distribution contract to take tokens and sell tokens for Ether
     * @param amount Amount of PRDX to sell
     * @return success Success of transaction, only false if transaction failed
     */
    function approveAndSell(uint256 amount) public returns (bool success) {
        require(balanceOf(msg.sender) >= amount, "Sell amount exceeds user token balance") ;
        _approve(msg.sender, tokendistr_addr, amount) ; 
        
        require(tokendistr_contract.sell_PRDX(msg.sender, amount)) ; 
        return true ; 
    }
    

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(uint256 amount) public {
        require(msg.sender != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(msg.sender, address(0), amount);

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

