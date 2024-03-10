pragma solidity ^0.5.11;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/ownership/Ownable.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Ownable implementation from an openzeppelin version.
 */
contract OpenZeppelinUpgradesOwnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @dev Adds new owner approval to the Ownable implementation.
 */
contract UAXCoinOwnable is OpenZeppelinUpgradesOwnable {
    address private _newOwner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _newOwner = newOwner;
    }

    /**
     * @dev Returns the address of the new owner.
     */
    function newOwner() public view returns (address) {
        return _newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyNewOwner() {
        require(msg.sender == _newOwner, "Ownable: caller is not a new owner");
        _;
    }

    /**
     * @dev New owner should approve ownership to avoid transfering to an invalid address.
     */
    function acceptOwnership() public onlyNewOwner {
        super._transferOwnership(_newOwner);
        _newOwner = address(0);
    }
}


/**
 * @dev Upgradeable coin controller contract.
 */
contract UAXCoinController is IERC20, UAXCoinOwnable {
    using SafeMath for uint256;

    UAXCoinAccounts private _accounts;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
    * @dev Whitelisted account only mode
    */
    bool private _useWhiteList;

    /**
     * @dev Contract has frozen accounts
     */
    bool private _hasFrozenAccounts;

    /**
     * @dev Emitted when the freeze is triggered for a specific account.
     */
    event AccountFreeze(address account);

    /**
     * @dev Emitted when the unfreeze is triggered for a specific account.
     */
    event AccountUnfreeze(address account);

    /**
     * @dev Sets initial data
     */
    function initialize() public onlyOwner {
        _name = 'UAX';
        _symbol = 'UAX';
        _decimals = 2;
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
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Sets new token name.
     */
    function setName(string memory newName) public onlyOwner {
        _name = newName;
    }

    /**
     * @dev Sets new token symbol.
     */
    function setSymbol(string memory newSymbol) public onlyOwner {
        _symbol = newSymbol;
    }

    /**
     * @dev Accounts contract
     */
    function setAccounts(UAXCoinAccounts accounts) public onlyOwner {
        _accounts = accounts;
        _hasFrozenAccounts = accounts.hasFrozen();
    }

    /**
     * @dev totalSupply proxy
     */
    function totalSupply() public view returns (uint256) {
        return _accounts.totalSupply();
    }

    /**
     * @dev balanceOf proxy
     */
    function balanceOf(address account) public view returns (uint256) {
        return _accounts.balanceOf(account);
    }

    /**
     * @dev allowance proxy
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _accounts.allowance(owner, spender);
    }

    /**
     * @dev Returns whitelisted accounts only mode state
     */
    function isWhitelistedModeActive() public view returns (bool) {
        return _useWhiteList;
    }

    /**
     * @dev Sets or resets mode when only whitelisted accounts are allowed
     */
    function allowWhitelistedAccountsOnly(bool value) public onlyOwner {
        _useWhiteList = value;
    }

    /**
     * @dev Freeze account
     */
    function freeze(address account) public onlyOwner {
        _accounts.freeze(account);
        _hasFrozenAccounts = true;
        emit AccountFreeze(account);
    }

    /**
     * @dev Unfreeze account
     */
    function unfreeze(address account) public onlyOwner {
        _accounts.unfreeze(account);
        _hasFrozenAccounts = _accounts.hasFrozen();
        emit AccountUnfreeze(account);
    }

    /**
     * @dev Marks address as whitelisted
     */
    function addToWhitelist(address account) public onlyOwner {
        _accounts.addToWhitelist(account);
    }

    /**
     * @dev Clears address whitelisted flag
     */
    function removeFromWhiteList(address account) public onlyOwner {
        _accounts.removeFromWhiteList(account);
    }

    function setNonce(address _address, uint256 _nonce) private {
        _accounts.setNonce(_address, _nonce);
    }

    /**
     * @dev transfer
     */
    function transfer(address to, uint256 value) public returns(bool) {
        if (_useWhiteList) {
            require(_accounts.bothWhitelisted(msg.sender, to), "Unknown account");
        }
        if (_hasFrozenAccounts) {
            require(!_accounts.anyFrozen(msg.sender, to), "Frozen account");
        }
        
        _transfer(msg.sender, to, value);

        return true;
    }

    /**
     * @dev ERC20 approve implementation
     */
    function approve(address spender, uint256 value) public returns(bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev ERC20 transferFrom implementation
     */
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        if (_useWhiteList) {
            require(_accounts.bothWhitelisted(from, to), "Unknown account");
        }
        if (_hasFrozenAccounts) {
            require(!_accounts.anyFrozen(from, to), "Frozen account");
        }
        uint256 allowanceValue = _accounts.allowance(from, msg.sender);
        allowanceValue = allowanceValue.sub(value);
        _approve(from, msg.sender, allowanceValue);

        _transfer(from, to, value);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     */
    function increaseAllowance(address spender, uint256 value) public returns (bool) {
        uint256 allowanceValue = _accounts.allowance(msg.sender, spender);
        allowanceValue = allowanceValue.add(value);
        _approve(msg.sender, spender, allowanceValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     */
    function decreaseAllowance(address spender, uint256 value)  public returns (bool) {
        uint256 allowanceValue = _accounts.allowance(msg.sender, spender);
        allowanceValue = allowanceValue.sub(value);
        _approve(msg.sender, spender, allowanceValue);
        return true;
    }

    /**
     * @dev Issue tokens to an account
     */
    function issue(uint256 value) public onlyOwner {
        _accounts.addBalanceAndTotalSupply(msg.sender, value);
        emit Transfer(address(0x0), msg.sender, value);
    }

    function delegatedTransfer(
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        returns (bool)
    {
        if (_useWhiteList) {
            require(_accounts.isWhitelisted(_to), "Unknown account");
        }
        if (_hasFrozenAccounts) {
            require(!_accounts.isFrozen(_to), "Frozen account");
        }

        address _from = ecrecover(
            keccak256(
                abi.encodePacked(
                    address(this), msg.sender, _to, _value, _fee, _nonce
                )
            ),
            _v, _r, _s
        );

        if (_useWhiteList) {
            require(_accounts.isWhitelisted(_from), "Unknown account");
        }
        if (_hasFrozenAccounts) {
            require(!_accounts.isFrozen(_from), "Frozen account");
        }
        require(_nonce == nonce(_from), "Invalid nonce");
        require(_fee.add(_value) <= balanceOf(_from), "Invalid balance");
        require(
            _to != address(0),
            "ERC20: delegated transfer to the zero address"
        );

        setNonce(_from, _nonce.add(1));

        _accounts.transferToTwo(_from, _to, msg.sender, _value, _fee);

        emit Transfer(_from, _to, _value);
        emit Transfer(_from, msg.sender, _fee);

        return true;

    }

    function delegatedMultiTransfer(
        address[] memory _to_arr,
        uint256[] memory _value_arr,
        uint256[] memory _fee_arr,
        uint256[] memory _nonce_arr,
        uint8[] memory _v_arr,
        bytes32[] memory _r_arr,
        bytes32[] memory _s_arr
    )
    public
    returns (bool)
    {
        require(
            _to_arr.length == _value_arr.length &&
            _to_arr.length == _fee_arr.length &&
            _to_arr.length == _nonce_arr.length &&
            _to_arr.length == _v_arr.length &&
            _to_arr.length == _r_arr.length &&
            _to_arr.length == _s_arr.length,
            'Incorrect input length'
        );

        for (uint i = 0; i < _to_arr.length; i++) {
            delegatedTransfer(
                _to_arr[i],
                _value_arr[i],
                _fee_arr[i],
                _nonce_arr[i],
                _v_arr[i],
                _r_arr[i],
                _s_arr[i]
            );
        }
    }

    function nonce(address _address) public view returns (uint256) {
        return _accounts.nonce(_address);
    }

    /**
     * @dev Burn tokens from an account
     */
    function burn(uint256 value) public onlyOwner {
        _accounts.subBalanceAndTotalSupply(msg.sender, value);
        emit Transfer(msg.sender, address(0x0), value);
    }

    /**
     * @dev ERC20 transfer implementation
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "ERC20: transfer to the zero address");
        _accounts.transfer(from, to, value);
        emit Transfer(from, to, value);
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

        _accounts.setAllowance(owner, spender, value);
        emit Approval(owner, spender, value);
    }
}


/**
 * @dev Token accounts contract.
 */
contract UAXCoinAccounts is UAXCoinOwnable {
    using SafeMath for uint256;

    mapping(address => uint256) private _nonces;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    UAXCoinController private _ctrl;

    mapping (address => bool) private _whitelist;
    mapping (address => bool) private _frozen;

    /**
     * @dev Indicates that some accounts may be frozen
     */
    bool private _hasFrozenAccounts;

    /**
     * @dev Number of frozen accounts
     */
    uint16 private _frozenCount;

    /**
     * @dev Initial values
     */
    constructor() public {
    }

    /**
     * @dev Modifier for methods that should be called only from the controller contract
     */
    modifier onlyController {
        require(msg.sender == address(_ctrl), "Ownable: not a controller");
        _;
    }

    /**
     * @dev Move tokens from one address to another
     */
    function transfer(address from, address to, uint256 value ) external onlyController {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
    }

    /**
     * @dev Move tokens from one address to two other addresses (e.g. send with fee collection)
     */
    function transferToTwo(address from, address to1, address to2, uint256 value1, uint256 value2) external onlyController {
        uint256 value = value1.add(value2);
        _balances[from] = _balances[from].sub(value);
        _balances[to1] = _balances[to1].add(value1);
        _balances[to2] = _balances[to2].add(value2);
    }

    /**
     * @dev Add a value to balance and totalSupply
     */
    function addBalanceAndTotalSupply(address owner, uint256 value) external onlyController {
        _balances[owner] = _balances[owner].add(value);
        _totalSupply = _totalSupply.add(value);
    }

    /**
     * @dev Add a value to balance and totalSupply
     */
    function subBalanceAndTotalSupply(address owner, uint256 value) external onlyController {
        _balances[owner] = _balances[owner].sub(value);
        _totalSupply = _totalSupply.sub(value);
    }

    /**
     * @dev Set allowance value
     */
    function setAllowance(address owner, address spender, uint256 allowance) external onlyController {
        _allowances[owner][spender] = allowance;
    }

    /**
     * @dev Sets account as whitelisted one
     */
    function addToWhitelist(address account) external onlyController {
        _whitelist[account] = true;
    }

    /**
     * @dev Sets account as not-whitelisted one
     */
    function removeFromWhiteList(address account) external onlyController {
        _whitelist[account] = false;
    }

    function nonce(address account) external onlyController view returns (uint256) {
        return _nonces[account];
    }

    function setNonce(address account, uint256 _nonce) external onlyController {
        _nonces[account] = _nonce;
    }
    /**
     * @dev Returns true for frozen accounts
     */
    function isFrozen(address account) external view onlyController returns(bool) {
        return _frozen[account];
    }

    /**
     * @dev Returns true if any of given accounts are frozen
     */
    function anyFrozen(address account1, address account2) external view onlyController returns(bool) {
        return _frozen[account1] || _frozen[account2];
    }

    /**
     * @dev Sets new controller contract address
     */
    function setController(UAXCoinController ctrl) public onlyOwner {
        _ctrl = ctrl;
    }

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view onlyController returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view onlyController returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view onlyController returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Returns true for whitelisted accounts
     */
    function isWhitelisted(address account) public view onlyController returns(bool) {
        return _whitelist[account];
    }

    /**
     * @dev Returns true for whitelisted accounts
     */
    function bothWhitelisted(address account1, address account2) public view onlyController returns(bool) {
        return _whitelist[account1] && _whitelist[account2];
    }

    /**
     * @dev Sets account as frozen one
     */
    function freeze(address account) public onlyController {
        if (!_frozen[account]) {
            _frozenCount++;
            _frozen[account] = true;
            _hasFrozenAccounts = true;
        }
    }

    /**
     * @dev Sets account as unfrozen one
     */
    function unfreeze(address account) public onlyController {
        if (_frozen[account]) {
            _frozenCount--;
            _frozen[account] = false;
            _hasFrozenAccounts = (_frozenCount > 0);
        }
    }

    /**
     * @dev Returns true if there were frozen accounts
     */
    function hasFrozen() public view returns(bool) {
        return _hasFrozenAccounts;
    }
}
