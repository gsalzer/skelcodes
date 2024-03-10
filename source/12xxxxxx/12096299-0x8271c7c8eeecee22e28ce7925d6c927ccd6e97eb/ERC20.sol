// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    struct Account {
        uint balance;
        uint lastDividends;
    }

    mapping (address => Account) public _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _totalDividendPoints = 0;
    uint256 private _unclaimedDividends = 0;
    uint256 private _pointMultiplier = 10 ** 18;
    uint256 private _minimumSupply = 69420;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 0;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        uint256 newDividendPoints = 0;
        if (_totalDividendPoints > _balances[account].lastDividends) {
            newDividendPoints = _totalDividendPoints.sub(_balances[account].lastDividends);
        }
        uint256 owing = (_balances[account].balance.mul(newDividendPoints)).div(_pointMultiplier);
        return _balances[account].balance.add(owing);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) _updateDividendModifier(msg.sender) _updateDividendModifier(recipient) public virtual override returns (bool) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) _updateDividendModifier(sender) _updateDividendModifier(recipient) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "PiPiCoin: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "PiPiCoin: decreased allowance below zero"));
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
        require(sender != address(0), "PiPiCoin: transfer from the zero address");
        require(recipient != address(0), "PiPiCoin: transfer to the zero address");
        require(_balances[sender].balance >= amount, "PiPiCoin: transfer amount exceeds balance");

        _beforeTokenTransfer(sender, recipient, amount);
        uint256 dividend = _disburse(sender, amount.div(50));
        uint256 amountAfterBurn = _partialBurn(sender, amount);

        _balances[sender].balance = _balances[sender].balance.sub(amountAfterBurn - dividend, "PiPiCoin: transfer amount exceeds balance");
        _balances[recipient].balance = _balances[recipient].balance.add(amountAfterBurn - dividend);
        emit Transfer(sender, recipient, amountAfterBurn - dividend);
    }

    function _disburse(address sender, uint amount) public returns(uint256) {
        if (amount < 1) {
            return 0;
        }
        _totalDividendPoints = _totalDividendPoints.add((amount.mul(_pointMultiplier)).div(_totalSupply));
        _unclaimedDividends =  _unclaimedDividends.add(amount);

        uint256 newDividendPoints = 0;
        if (_totalDividendPoints > _balances[sender].lastDividends) {
            newDividendPoints = _totalDividendPoints.sub(_balances[sender].lastDividends);
        }
        uint256 owing = (_balances[sender].balance.mul(newDividendPoints)).div(_pointMultiplier);

        _updateDividend(sender);
        _balances[sender].balance = balanceOf(sender).sub(amount).sub(owing);
        return amount;
    }

    function _partialBurn(address sender, uint256 amount) internal returns (uint256) {
        if (amount < 100) {
            if (amount > 1) {
                _burn(sender, 1);
                return amount.sub(1);
            }
        }

        uint256 burnAmount = _calculateBurnAmount(amount);
        if (burnAmount > 0) {
            _burn(sender, burnAmount);
        }

        return amount.sub(burnAmount);
    }

    function _calculateBurnAmount(uint256 amount) internal view returns (uint256) {
        uint256 burnAmount = 0;

        // burn amount calculations
        if (totalSupply() > _minimumSupply) {
            burnAmount = amount.div(100);
            uint256 availableBurn = totalSupply().sub(_minimumSupply);
            if (burnAmount > availableBurn) {
                burnAmount = availableBurn;
            }
        }

        return burnAmount;
    }    

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "PiPiCoin: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account].balance = _balances[account].balance.add(amount);
        emit Transfer(address(0), account, amount);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "PiPiCoin: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account].balance = _balances[account].balance.sub(amount, "PiPiCoin: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
        require(owner != address(0), "PiPiCoin: approve from the zero address");
        require(spender != address(0), "PiPiCoin: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }


    modifier _updateDividendModifier(address investor) {
        _updateDividend(investor);
        _;
    }

    function _updateDividend(address investor) internal virtual {
        uint256 owing = _dividendsOwing(investor);
        if(owing > 0) {
            _unclaimedDividends = _unclaimedDividends.sub(owing);
            _balances[investor].balance = _balances[investor].balance.add(owing);
            _balances[investor].lastDividends = _totalDividendPoints;
        }
    }

    function _dividendsOwing(address investor) internal view returns(uint256) {
        uint256 newDividendPoints = _totalDividendPoints.sub(_balances[investor].lastDividends);
        return (_balances[investor].balance.mul(newDividendPoints)).div(_pointMultiplier);
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
