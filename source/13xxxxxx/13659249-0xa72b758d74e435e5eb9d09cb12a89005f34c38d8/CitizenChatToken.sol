pragma solidity 0.8.6;

//SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/**
 * @dev {CitizenChatToken} token, including:
 *
 *  - Preminted initial supply
 *  - Pausable
 *  - VestedTokens
 *
 */
contract CitizenChatToken is Pausable, Ownable, IERC20, IERC20Metadata {
    struct VestedRecord {
        bool isVested;
        uint256 lockedUpto;
        uint256 amount;
    }

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => VestedRecord) private vestedRecords;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    /**
     * @dev Emitted when `value` tokens are vested from owner (`from`) to
     * another (`to`).
     *
     */
    event VestedTransfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    /**
     * @dev Emitted when `value` tokens are Withdrawn from vested record to
     * another (`beneficiary`).
     *
     */
    event VestedWithdraw(address beneficiary, uint256 value);

    /**
     *
     * @dev Sets the values for {name} and {symbol}. Mints `initialSupply` amount of token and transfers them to `owner`
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        address ownerAddress
    ) {
        _name = name_;
        _symbol = symbol_;

        _mint(ownerAddress, initialSupply * 10**18);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account] + vestedBalanceOf(account);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer();

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer();

        _totalSupply += amount;
        _balances[account] += amount;
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer();

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev onlyOwner can pause the token transfer
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev onlyOwner can unpause the token transfer
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev hook function for before any token transfer.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer() internal view {
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    /**
     * @dev Send tokens to bulk address
     *
     * Requirements:
     *
     * - onlyOwner can do bulk transfer
     * - `recipients` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function bulkTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner returns (bool) {
        require(
            recipients.length == amounts.length,
            "CCT: Equal length arrays must"
        );

        for (uint8 i = 0; i < recipients.length; i++) {
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }

        return true;
    }

    /**
     * @dev Vesting Transfer
     *
     * Requirements:
     *
     * - onlyOwner can do Vesting transfer
     * - `beneficiary` cannot be the zero address.
     * - `lockedUpto` a certain period
     * - the caller must have a balance of at least `amount`.
     */
    function vestingTransfer(
        address beneficiary,
        uint256 lockedUpto,
        uint256 amount
    ) public onlyOwner returns (bool) {
        require(
            beneficiary != address(0),
            "ERC20: transfer to the zero address"
        );

        VestedRecord memory vestRecord = vestedRecords[beneficiary];

        require(vestRecord.isVested == false, "CCT: Tokens already vested");

        uint256 senderBalance = _balances[_msgSender()];

        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
            _balances[_msgSender()] = senderBalance - amount;
        }

        vestedRecords[beneficiary] = VestedRecord(true, lockedUpto, amount);

        emit VestedTransfer(_msgSender(), beneficiary, amount);

        return true;
    }

    /**
     * @dev Withdraw Vesting Tokens
     *
     * Requirements:
     *
     * - `beneficiary` cannot be the zero address.
     */
    function WithdrawVestedTokens(address beneficiary) public returns (bool) {
        VestedRecord memory vestRecord = vestedRecords[beneficiary];

        require(vestRecord.isVested == true, "CCT: No Vested tokens");
        require(block.timestamp > vestRecord.lockedUpto, "CCT: Locked Tokens");

        _balances[beneficiary] = _balances[beneficiary] + vestRecord.amount;

        emit VestedWithdraw(beneficiary, vestRecord.amount);

        delete vestedRecords[beneficiary];

        return true;
    }

    /**
     * @dev Vested Balance
     *
     * Requirements:
     * - `beneficiary` cannot be the zero address.
     */
    function vestedBalanceOf(address beneficiary)
        public
        view
        returns (uint256)
    {
        VestedRecord memory vestRecord = vestedRecords[beneficiary];

        return vestRecord.amount;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual onlyOwner {
        _burn(_msgSender(), amount);
    }
}

