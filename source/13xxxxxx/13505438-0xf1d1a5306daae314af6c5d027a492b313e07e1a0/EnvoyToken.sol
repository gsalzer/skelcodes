/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


contract EnvoyToken is ERC20 {

  using SafeMath for uint256;

  //
  // ******************* VARIABLES *******************
  //

  // Deploy time
  uint256 private _deployTime = 1635429600; 
  uint256 private _startTime = 1635933600; 

  // Contract owner
  address public _ownerWallet;

  // Public sale - 1M
  address public _publicSaleWallet;
  // Team - 20M
  address public _teamWallet;
  // Ecosystem - 25M
  address public _ecosystemWallet;
  // Reserves - 20M
  address public _reservesWallet;
  // DEX - 2M
  address public _dexWallet;
  // Liquidity incentives - 7M
  address public _liqWallet;

  // Amount of tokens per buyer in private sale - 25M
  mapping(address => uint256) public _buyerTokens;

  // Amount of tokens assigned to buyers
  uint256 public _totalBuyerTokens;

  // Amount of tokens a wallet has withdrawn already, per type
  mapping(string => mapping(address => uint256)) public _walletTokensWithdrawn;


  //
  // ******************* SETUP *******************
  //

  constructor (string memory name, string memory symbol) public ERC20(name, symbol) {

    // Set owner wallet
    _ownerWallet = _msgSender();

    // Mint 100M tokens for contract
    _mint(address(this), 100000000000000000000000000);
  }

  //
  // ******************* WALLETS SETUP *******************
  //

  // Owner can update owner
  function updateOwner(address owner) external {
    require(_msgSender() == _ownerWallet, "Only owner can update wallets");

    _ownerWallet = owner; 
  }

  // Update wallets
  function updateWallets(address publicSale, address team, address ecosystem, address reserves, address dex, address liq) external {
    require(_msgSender() == _ownerWallet, "Only owner can update wallets");

    require(publicSale != address(0), "Should not set zero address");
    require(team != address(0), "Should not set zero address");
    require(ecosystem != address(0), "Should not set zero address");
    require(reserves != address(0), "Should not set zero address");
    require(dex != address(0), "Should not set zero address");
    require(liq != address(0), "Should not set zero address");

    _walletTokensWithdrawn["publicsale"][publicSale] = _walletTokensWithdrawn["publicsale"][_publicSaleWallet];
    _walletTokensWithdrawn["team"][team] = _walletTokensWithdrawn["team"][_teamWallet];
    _walletTokensWithdrawn["ecosystem"][ecosystem] = _walletTokensWithdrawn["ecosystem"][_ecosystemWallet];
    _walletTokensWithdrawn["reserve"][reserves] = _walletTokensWithdrawn["reserve"][_reservesWallet];
    _walletTokensWithdrawn["dex"][dex] = _walletTokensWithdrawn["dex"][_dexWallet];
    _walletTokensWithdrawn["liq"][liq] = _walletTokensWithdrawn["liq"][_liqWallet];

    _publicSaleWallet = publicSale; 
    _teamWallet = team;
    _ecosystemWallet = ecosystem;
    _reservesWallet = reserves;
    _dexWallet = dex;
    _liqWallet = liq;
  }

  // Update buyer tokens
  function setBuyerTokens(address buyer, uint256 tokenAmount) external {
    require(_msgSender() == _ownerWallet, "Only owner can set buyer tokens");

    // Update total
    _totalBuyerTokens -= _buyerTokens[buyer];
    _totalBuyerTokens += tokenAmount;

    // Check if enough tokens left, can max assign 25M
    require(_totalBuyerTokens <= 25000000000000000000000000, "Max amount reached");

    // Update map
    _buyerTokens[buyer] = tokenAmount;
  }

  //
  // ******************* OWNER *******************
  //

  function publicSaleWithdraw(uint256 tokenAmount) external {
    require(_msgSender() == _publicSaleWallet, "Unauthorized public sale wallet");

    uint256 hasWithdrawn = _walletTokensWithdrawn["publicsale"][_msgSender()];

    // Total = 1M instant
    uint256 canWithdraw = 1000000000000000000000000 - hasWithdrawn;

    require(tokenAmount <= canWithdraw, "Withdraw amount too high");

    _walletTokensWithdrawn["publicsale"][_msgSender()] += tokenAmount;

    _transfer(address(this), _msgSender(), tokenAmount);    
  }

  function liqWithdraw(uint256 tokenAmount) external {
    require(_msgSender() == _liqWallet, "Unauthorized liquidity incentives wallet");

    // TGE = 40%
    // Cliff = 1 months = 43800 minutes
    // Vesting = 6 months 262800 minutes
    // Total = 20M
    uint256 canWithdraw = walletCanWithdraw(_msgSender(), "liq", 40, 43800, 262800, 7000000000000000000000000, _deployTime);
    
    require(tokenAmount <= canWithdraw, "Withdraw amount too high");

    _walletTokensWithdrawn["liq"][_msgSender()] += tokenAmount;

    _transfer(address(this), _msgSender(), tokenAmount);  
  
  }

  function teamWithdraw(uint256 tokenAmount) external {
    require(_msgSender() == _teamWallet, "Unauthorized team wallet");

    // Cliff = 6 months = 262800 minutes
    // Vesting = 20 months 876001 minutes
    // Total = 20M
    uint256 canWithdraw = walletCanWithdraw(_msgSender(), "team", 0, 262800, 876001, 20000000000000000000000000, _deployTime);
    
    require(tokenAmount <= canWithdraw, "Withdraw amount too high");

    _walletTokensWithdrawn["team"][_msgSender()] += tokenAmount;

    _transfer(address(this), _msgSender(), tokenAmount);  
  }

  function ecosystemWithdraw(uint256 tokenAmount) external {
    require(_msgSender() == _ecosystemWallet, "Unauthorized ecosystem wallet");

    // TGE = 5%
    // Cliff = 1 months = 43800 minutes
    // Vesting = 19 months = 832201 minutes
    // Total = 25M
    uint256 canWithdraw = walletCanWithdraw(_msgSender(), "ecosystem", 5, 43800, 832201, 25000000000000000000000000, _deployTime);
    
    require(tokenAmount <= canWithdraw, "Withdraw amount too high");

    _walletTokensWithdrawn["ecosystem"][_msgSender()] += tokenAmount;

    _transfer(address(this), _msgSender(), tokenAmount);  
  }

  function reservesWithdraw(uint256 tokenAmount) external {
    require(_msgSender() == _reservesWallet, "Unauthorized reserves wallet");

    // Cliff = 6 months = 262800 minutes
    // Vesting = 20 months = 876001 minutes
    // Total = 20M
    uint256 canWithdraw = walletCanWithdraw(_msgSender(), "reserve", 0, 262800, 876001, 20000000000000000000000000, _deployTime);
    
    require(tokenAmount <= canWithdraw, "Withdraw amount too high");

    _walletTokensWithdrawn["reserve"][_msgSender()] += tokenAmount;

    _transfer(address(this), _msgSender(), tokenAmount);  
  }

  function dexWithdraw(uint256 tokenAmount) external {
    require(_msgSender() == _dexWallet, "Unauthorized dex wallet");

    uint256 hasWithdrawn = _walletTokensWithdrawn["dex"][_msgSender()];

    // Total = 2M instant
    uint256 canWithdraw = 2000000000000000000000000 - hasWithdrawn;

    require(tokenAmount <= canWithdraw, "Withdraw amount too high");

    _walletTokensWithdrawn["dex"][_msgSender()] += tokenAmount;

    _transfer(address(this), _msgSender(), tokenAmount);    
  }

  function buyerWithdraw(uint256 tokenAmount) external {
    
    // TGE = 10%
    // Cliff = 4 months = 175200 minutes
    // Vesting = 18 months = 788401 minutes
    uint256 canWithdraw = walletCanWithdraw(_msgSender(), "privatesale", 10, 175200, 788401, _buyerTokens[_msgSender()], _startTime);
    
    require(tokenAmount <= canWithdraw, "Withdraw amount too high");

    _walletTokensWithdrawn["privatesale"][_msgSender()] += tokenAmount;

    _transfer(address(this), _msgSender(), tokenAmount);    
  }

  //
  // ******************* UNLOCK CALCULATION *******************
  //

  function walletCanWithdraw(address wallet, string memory walletType, uint256 initialPercentage, uint256 cliffMinutes, uint256 vestingMinutes, uint256 totalTokens, uint256 startTime) public view returns(uint256) {
    
    uint256 minutesDiff = (block.timestamp - startTime).div(60);

    // Tokens already withdrawn
    uint256 withdrawnTokens = _walletTokensWithdrawn[walletType][wallet];

    // Initial tokens
    uint256 initialTokens = 0;
    if (initialPercentage != 0) {
      initialTokens = totalTokens.mul(initialPercentage).div(100);
    }

    // Cliff not ended
    if (minutesDiff < uint256(cliffMinutes)) {
      return initialTokens - withdrawnTokens;
    }

    // Tokens per minute over vesting period
    uint256 buyerTokensPerMinute = totalTokens.sub(initialTokens).div(vestingMinutes); 

    // Advanced minutes minus cliff
    uint256 unlockedMinutes = minutesDiff - uint256(cliffMinutes); 

    // Unlocked minutes * tokens per minutes + initial tokens
    uint256 unlockedTokens = unlockedMinutes.mul(buyerTokensPerMinute).add(initialTokens); 
    
    // No extra tokens unlocked
    if (unlockedTokens <= withdrawnTokens) {
      return 0;
    }

    // Check if buyer reached max
    if (unlockedTokens > totalTokens) {
      return totalTokens - withdrawnTokens;
    }

    // Result
    return unlockedTokens - withdrawnTokens;
  }

}
