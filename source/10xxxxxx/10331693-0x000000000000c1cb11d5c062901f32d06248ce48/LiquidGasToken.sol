// SPDX-License-Identifier: MIT

pragma solidity 0.6.9;


// Part: IERC20

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

// Part: SafeMath

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Part: ERC20PointerSupply

/// @title ERC20-Token where total supply is calculated from minted and burned tokens
/// @author Matthias Nadler
contract ERC20PointerSupply is IERC20 {
    using SafeMath for uint256;

    // ****** ERC20 Pointer Supply Token
    //        --------------------------
    //        totalSupply is stored in two variables:
    //        The number of tokens minted and burned, where minted - burned = totalSupply.
    //        Additionally, the supply is split into:
    //        - ownedSupply: Number of tokens owned by accounts.
    //        - tokenReserves: Implicitly defined as totalSupply - ownedSupply, this is the number
    //                        of tokens "owned" by this contract.
    //        To keep the contract more gas efficient, no Transfer events are emitted when
    //        minting or burning tokens.

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _ownedSupply;
    uint256 internal _totalBurned;
    uint256 internal _totalMinted;

    string constant public name = "Liquid Gas Token";
    string constant public symbol = "LGT";
    uint8 constant public decimals = 0;

    /// @notice Return the total supply of tokens.
    /// @dev This is different from a classic ERC20 implementation as the supply is calculated
    ///      from the burned and minted tokens instead of stored in its own variable.
    /// @return Total number of tokens in circulation.
    function totalSupply() public view override returns (uint256) {
        return _totalMinted.sub(_totalBurned);
    }

    /// @notice Return the number of tokens owned by accounts.
    /// @dev Unowned tokens belong to this contract and their supply can be
    ///      calculated implicitly. This means we need to manually track owned tokens,
    ///      but it makes operations on unowned tokens much more efficient.
    /// @return Total number of tokens owned by specific addresses.
    function ownedSupply() external view returns (uint256) {
        return _ownedSupply;
    }

    /// @notice Returns the amount of tokens owned by `account`.
    /// @param account The account to query for the balance.
    /// @return The amount of tokens owned by `account`.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    ///         Emits a {Transfer} event.
    /// @dev Requirements:
    //       - `recipient` cannot be the zero address.
    //       - the caller must have a balance of at least `amount`.
    /// @param recipient The tokens are transferred to this address.
    /// @param amount The amount of tokens to be transferred.
    /// @return True if the transfer succeeded, False otherwise.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Returns the remaining number of tokens that `spender` will be
    ///         allowed to spend on behalf of `owner` through {transferFrom}.
    ///         This is zero by default.
    /// @param owner The address that holds the tokens that can be spent by `spender`.
    /// @param spender The address that is allowed to spend the tokens held by `owner`.
    /// @return Remaining number of tokens that `spender` will be
    ///         allowed to spend on behalf of `owner`
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///         Emits an {Approval} event.
    /// @dev    IMPORTANT: Beware that changing an allowance with this method brings the risk
    ///         that someone may use both the old and the new allowance by unfortunate
    ///         transaction ordering. This contracts provides {increaseAllowance} and
    ///         {decreaseAllowance} to mitigate this problem. See:
    ///         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///         Requirements:
    ///         - `spender` cannot be the zero address.
    /// @param spender The address that is allowed to spend the tokens held by the caller.
    /// @param amount The amount of tokens the `spender` can spend from the caller's supply.
    /// @return True if the approval succeeded, False otherwise.
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }


    /// @notice Moves `amount` tokens from `sender` to `recipient` using the allowance
    ///         mechanism. `amount` is then deducted from the caller's allowance.
    ///         Emits a {Transfer} and an {Approval} event.
    /// @dev Requirements:
    ///      - `sender` and `recipient` cannot be the zero address.
    ///      - `sender` must have a balance of at least `amount`.
    ///      - the caller must have allowance for `sender`'s tokens of at least `amount`.
    /// @param sender The tokens are transferred from this address.
    /// @param recipient The tokens are transferred to this address.
    /// @param amount The amount of tokens to be transferred.
    /// @return True if the transfer succeeded, False otherwise.
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, "ERC20: exceeds allowance")
        );
        return true;
    }

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///         This is an alternative to {approve} that can be used as a mitigation for
    ///         problems described in {approve}.
    ///         Emits an {Approval} event.
    /// @dev Requirements:
    ///      - `spender` cannot be the zero address.
    /// @param spender The address that is allowed to spend the tokens held by the caller.
    /// @param addedValue The amount of tokens to add to the current `allowance`.
    /// @return True if the approval succeeded, False otherwise.
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    ///         This is an alternative to {approve} that can be used as a mitigation for
    ///         problems described in {approve}.
    ///         Emits an {Approval} event.
    /// @dev Requirements:
    ///      - `spender` cannot be the zero address.
    ///      - `spender` must have allowance for the caller of at least `subtractedValue`.
    /// @param spender The address that is allowed to spend the tokens held by the caller.
    /// @param subtractedValue The amount of tokens to subtract from the current `allowance`.
    /// @return True if the approval succeeded, False otherwise.
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: allowance below zero")
        );
        return true;
    }


    // ****** Internal ERC20 Functions
    //        ------------------------

    /// @dev Triggered when tokens are transferred to this contract.
    ///      Can be overridden by an implementation to allow and handle this behaviour.
    ///      This should emit a {Transfer} event if an ownership change is made.
    function _transferToSelf(address sender, uint256 amount) internal virtual {
        revert("ERC20: transfer to contract");
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(recipient != address(0), "ERC20: transfer to zero address");
        if (recipient == address(this)) {
            _transferToSelf(sender, amount);
        } else {
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer exceeds balance");
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// Part: LiquidERC20

/// @title ERC20-Token with built in Liquidity Pool
/// @dev The Liquidity Shares do not adhere to ERC20 standards,
///      only the underlying token does. Liquidity can not be traded.
/// @author Matthias Nadler
contract LiquidERC20 is ERC20PointerSupply {

    // ***** Liquidity Pool
    //       --------------
    //       Integrated Liquidity Pool for an ERC20 Pointer Supply Token.
    //       More efficient due to shortcuts in the ownership transfers.
    //       Modelled after Uniswap V1 by Hayden Adams:
    //       https://github.com/Uniswap/uniswap-v1/blob/master/contracts/uniswap_exchange.vy
    //       Sell and Buy events are not implemented in the interest of gas efficiency.
    //       Liquidity shares do not adhere to ERC20 specifications.
    //       However, a subset of ERC20-like functions are implemented.

    uint256 internal _poolTotalSupply;
    mapping (address => uint256) internal _poolBalances;

    event AddLiquidity(
        address indexed provider,
        uint256 indexed eth_amount,
        uint256 indexed token_amount
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256 indexed eth_amount,
        uint256 indexed token_amount
    );
    event TransferLiquidity(
        address indexed from,
        address indexed to,
        uint256 value
    );

    /// @notice Returns the amount of liquidity shares owned by `account`.
    /// @param account The account to query for the balance.
    /// @return The amount of liquidity shares owned by `account`.
    function poolBalanceOf(address account) external view returns (uint256) {
        return _poolBalances[account];
    }

    /// @notice Return the total supply of liquidity shares.
    /// @return Total number of liquidity shares.
    function poolTotalSupply() external view returns (uint256) {
        return _poolTotalSupply;
    }

    /// @notice The amount of tokens in the liquidity pool.
    /// @dev This is defined implicitly as the difference between
    ///      The total supply and the privately owned supply of the token.
    /// @return The amount of tokens in the liquidity pool.
    function poolTokenReserves() external view returns (uint256) {
        return _totalMinted.sub(_totalBurned + _ownedSupply);
    }

    /// @notice Moves `amount` liquidity shares from the caller's account to `recipient`.
    ///         Emits a {Transfer} event.
    /// @dev Requirements:
    //       - `recipient` cannot be the zero address.
    //       - the caller must have a balance of at least `amount`.
    /// @param recipient The tokens are transferred to this address.
    /// @param amount The amount of tokens to be transferred.
    /// @return True if the transfer succeeded, False otherwise.
    function poolTransfer(address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0)); // dev: can't transfer liquidity to zero address
        require(recipient != address(this)); // dev: can't transfer liquidity to token contract
        _poolBalances[msg.sender] = _poolBalances[msg.sender].sub(amount, "LGT: transfer exceeds balance");
        _poolBalances[recipient]= _poolBalances[recipient].add(amount);
        emit TransferLiquidity(msg.sender, recipient, amount);
        return true;
    }

    // *** Constructor
    /// @dev Start with initial liquidity. Contract must be pre-funded.
    ///      This initial liquidity must never be removed.
    constructor() public {
        // Implementation must mint at least 1 token to the pool during deployment.
        uint ethReserve = address(this).balance;
        require(ethReserve > 1000000000);
        _poolTotalSupply += ethReserve;
        _poolBalances[msg.sender] += ethReserve;
    }

    // ***** Liquidity Pool
    //       --------------------
    //       Add, remove or transfer liquidity shares.

    /// @notice Add liquidity to the pool and receive liquidity shares. Must deposit
    ///         an equal amount of ether and tokens at the current exchange rate.
    ///         Emits an {AddLiquidity} event.
    /// @param minLiquidity The minimum amount of liquidity shares to create,
    ///        will revert if not enough liquidity can be created.
    /// @param maxTokens The maximum amount of tokens to transfer to match the provided
    ///        ether liquidity. Will revert if too many tokens are needed.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @return The amount of liquidity shares created.
    function addLiquidity(uint256 minLiquidity, uint256 maxTokens, uint256 deadline)
        external
        payable
        returns (uint256)
    {
        require(deadline >= now); // dev: deadline passed
        require(maxTokens != 0); // dev: no tokens to add
        require(msg.value != 0); // dev: no ether to add
        require(minLiquidity != 0); // dev: no min_liquidity specified

        uint256 ethReserve = address(this).balance - msg.value;
        uint256 ownedSupply = _ownedSupply;
        uint256 tokenReserve = _totalMinted.sub(_totalBurned + ownedSupply);
        uint256 tokenAmount = msg.value.mul(tokenReserve) / ethReserve + 1;
        uint256 poolTotalSupply = _poolTotalSupply;
        uint256 liquidityCreated = msg.value.mul(poolTotalSupply) / ethReserve;
        require(maxTokens >= tokenAmount); // dev: need more tokens
        require(liquidityCreated >= minLiquidity); // dev: not enough liquidity can be created

        // create liquidity shares
        _poolTotalSupply = poolTotalSupply + liquidityCreated;
        _poolBalances[msg.sender] += liquidityCreated;

        // remove LGTs from sender
        _balances[msg.sender] = _balances[msg.sender].sub(
            tokenAmount, "LGT: amount exceeds balance"
        );
        _ownedSupply = ownedSupply.sub(tokenAmount);

        emit AddLiquidity(msg.sender, msg.value, tokenAmount);
        return liquidityCreated;
    }


    /// @notice Remove liquidity shares and receive an equal amount of tokens and ether
    ///         at the current exchange rate from the liquidity pool.
    ///         Emits a {RemoveLiquidity} event.
    /// @param amount The amount of liquidity shares to remove from the pool.
    /// @param minEth The minimum amount of ether you want to receive in the transaction.
    ///        Will revert if less than `minEth` ether would be transferred.
    /// @param minTokens The minimum amount of tokens you want to receive in the transaction.
    ///        Will revert if less than `minTokens` tokens would be transferred.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @dev Requirements:
    ///      - `sender` must have a liquidity pool balance of at least `amount`.
    /// @return The amount of ether and tokens refunded.
    function removeLiquidity(uint256 amount, uint256 minEth, uint256 minTokens, uint256 deadline)
        external
        returns (uint256, uint256)
    {
        require(deadline >= now); // dev: deadline passed
        require(amount != 0); // dev: amount of liquidity to remove must be positive
        require(minEth != 0); // dev: must remove positive eth amount
        require(minTokens != 0); // dev: must remove positive token amount
        uint256 totalLiquidity = _poolTotalSupply;
        uint256 ownedSupply = _ownedSupply;
        uint256 tokenReserve = _totalMinted.sub(_totalBurned + ownedSupply);
        uint256 ethAmount = amount.mul(address(this).balance) / totalLiquidity;
        uint256 tokenAmount = amount.mul(tokenReserve) / totalLiquidity;
        require(ethAmount >= minEth); // dev: can't remove enough eth
        require(tokenAmount >= minTokens); // dev: can't remove enough tokens

        // Remove liquidity shares
        _poolBalances[msg.sender] = _poolBalances[msg.sender].sub(amount);
        _poolTotalSupply = totalLiquidity.sub(amount);

        // Transfer tokens
        _balances[msg.sender] += tokenAmount;
        _ownedSupply = ownedSupply + tokenAmount;

        emit RemoveLiquidity(msg.sender, ethAmount, tokenAmount);

        // Transfer ether
        msg.sender.call{value: ethAmount}("");

        return (ethAmount, tokenAmount);
    }

    // ***** Constant Price Model
    //       --------------------
    //       Internal price calculation functions for the constant price model with fees.


    /// @dev token reserve and pool balance are guaranteed to be non-zero
    ///      No need to require inputReserve != 0
    function getInputPrice(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve)
        internal
        pure
        returns (uint256)
    {
        uint256 inputAmountWithFee = inputAmount.mul(995);
        uint256 numerator = inputAmountWithFee.mul(outputReserve);
        uint256 denominator = inputReserve.mul(1000).add(inputAmountWithFee);
        return numerator / denominator;
    }

    /// @dev Requirements:
    ///      - `OutputAmount` must be greater than `OutputReserve`
    ///      Token reserve and pool balance are guaranteed to be non-zero
    ///      No need to require inputReserve != 0 or outputReserve != 0
    function getOutputPrice(uint256 outputAmount, uint256 inputReserve, uint256 outputReserve)
        internal
        pure
        returns (uint256)
    {
        uint256 numerator = inputReserve.mul(outputAmount).mul(1000);
        uint256 denominator = outputReserve.sub(outputAmount).mul(995);
        return numerator.div(denominator).add(1);
    }

    // ***** Trade Ether to Tokens
    //       -------------------

    /// @dev Exact amount of ether -> As many tokens as can be bought, without partial refund
    function ethToTokenInput(
        uint256 ethSold,
        uint256 minTokens,
        uint256 deadline,
        address recipient
    )
        internal
        returns (uint256)
    {
        require(deadline >= now); // dev: deadline passed
        require(ethSold != 0); // dev: no eth to sell
        require(minTokens != 0); // dev: must buy one or more tokens
        uint256 ownedSupply = _ownedSupply;
        uint256 tokenReserve = _totalMinted.sub(_totalBurned + ownedSupply);
        uint256 ethReserve = address(this).balance.sub(ethSold);
        uint256 tokensBought = getInputPrice(ethSold, ethReserve, tokenReserve);
        require(tokensBought >= minTokens); // dev: not enough eth to buy tokens
        _balances[recipient] += tokensBought;
        _ownedSupply = ownedSupply + tokensBought;
        return tokensBought;
    }

    /// @notice Convert ETH to Tokens
    /// @dev User cannot specify minimum output or deadline.
    receive() external payable {
        ethToTokenInput(msg.value, 1, now, msg.sender);
    }

    /// @notice Convert ether to tokens. Specify the exact input (in ether) and
    ///         the minimum output (in tokens).
    /// @param minTokens The minimum amount of tokens you want to receive in the
    ///        transaction for your sold ether. Will revert if less than `minTokens`
    ///        tokens would be transferred.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @dev Excess ether for buying a partial token is not refunded.
    /// @return The amount of tokens bought.
    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline)
        external
        payable
        returns (uint256)
    {
        return ethToTokenInput(msg.value, minTokens, deadline, msg.sender);
    }

    /// @notice Convert ether to tokens and transfer tokens to `recipient`.
    ///         Specify the exact input (in ether) and the minimum output (in tokens).
    /// @param minTokens The minimum amount of tokens you want the `recipient` to
    ///        receive in the transaction for your sold ether.
    ///        Will revert if less than `minTokens` tokens would be transferred.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @param recipient Bought tokens will be transferred to this address.
    /// @dev Excess ether for buying a partial token is not refunded.
    ///      Requirements:
    ///      - `recipient` can't be this contract or the zero address
    /// @return The amount of tokens bought and transferred to `recipient`.
    function ethToTokenTransferInput(uint256 minTokens, uint256 deadline, address recipient)
        external
        payable
        returns (uint256)
    {
        require(recipient != address(this)); // dev: can't send to liquid token contract
        require(recipient != address(0)); // dev: can't send to zero address
        return ethToTokenInput(msg.value, minTokens, deadline, recipient);
    }


    /// @dev Any amount of ether (at least cost of tokens) -> Exact amount of tokens + refund
    function ethToTokenOutput(
        uint256 tokensBought,
        uint256 maxEth,
        uint256 deadline,
        address payable buyer,
        address recipient
    )
        internal
        returns (uint256)
    {
        require(deadline >= now); // dev: deadline passed
        require(tokensBought != 0); // dev: must buy one or more tokens
        require(maxEth != 0); // dev: maxEth must greater than 0
        uint256 ownedSupply = _ownedSupply;
        uint256 tokenReserve = _totalMinted.sub(_totalBurned + ownedSupply);
        uint256 ethReserve = address(this).balance.sub(maxEth);
        uint256 ethSold = getOutputPrice(tokensBought, ethReserve, tokenReserve);
        uint256 ethRefund = maxEth.sub(ethSold, "LGT: not enough ETH");
        _balances[recipient] += tokensBought;
        _ownedSupply = ownedSupply + tokensBought;
        if (ethRefund != 0) {
            buyer.call{value: ethRefund}("");
        }
        return ethSold;
    }

    /// @notice Convert ether to tokens. Specify the maximum input (in ether) and
    ///         the exact output (in tokens). Any remaining ether is refunded.
    /// @param tokensBought The exact amount of tokens you want to receive.
    ///        Will revert if less than `tokensBought` tokens can be bought
    ///        with the sent amount of ether.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @dev Excess ether after buying `tokensBought` tokens is refunded.
    /// @return The amount of ether sold to buy `tokensBought` tokens.
    function ethToTokenSwapOutput(uint256 tokensBought, uint256 deadline)
        external
        payable
        returns (uint256)
    {
        return ethToTokenOutput(tokensBought, msg.value, deadline, msg.sender, msg.sender);
    }

    /// @notice Convert ether to tokens and transfer tokens to `recipient`.
    ///         Specify the maximum input (in ether) and the exact output (in tokens).
    ///         Any remaining ether is refunded.
    /// @param tokensBought The exact amount of tokens you want to buy and transfer to
    ///        `recipient`. Will revert if less than `tokensBought` tokens can be bought
    ///        with the sent amount of ether.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @param recipient Bought tokens will be transferred to this address.
    /// @dev Excess ether for buying a partial token is not refunded.
    ///      Requirements:
    ///      - `recipient` can't be this contract or the zero address
    /// @return The amount of ether sold to buy `tokensBought` tokens.
    function ethToTokenTransferOutput(uint256 tokensBought, uint256 deadline, address recipient)
        external
        payable
        returns (uint256)
    {
        require(recipient != address(this)); // dev: can't send to liquid token contract
        require(recipient != address(0)); // dev: can't send to zero address
        return ethToTokenOutput(tokensBought, msg.value, deadline, msg.sender, recipient);
    }


    // ***** Trade Tokens to Ether
    //       ---------------------

    /// @dev Exact amount of tokens -> Minimum amount of ether
    function tokenToEthInput(
        uint256 tokensSold,
        uint256 minEth,
        uint256 deadline,
        address buyer,
        address payable recipient
    ) internal returns (uint256) {
        require(deadline >= now); // dev: deadline passed
        require(tokensSold != 0); // dev: must sell one or more tokens
        require(minEth != 0); // dev: minEth not set
        uint256 ownedSupply = _ownedSupply;
        uint256 tokenReserve = _totalMinted.sub(_totalBurned + ownedSupply);
        uint256 ethBought = getInputPrice(tokensSold, tokenReserve, address(this).balance);
        require(ethBought >= minEth); // dev: tokens not worth enough
        _balances[buyer] = _balances[buyer].sub(tokensSold, "LGT: amount exceeds balance");
        _ownedSupply = ownedSupply.sub(tokensSold);
        recipient.call{value: ethBought}("");
        return ethBought;
    }

    /// @dev Transferring tokens to this contract will sell them.
    ///      User cannot specify minEth or deadline.
    function _transferToSelf(address sender, uint256 amount) internal override {
        address payable _sender = payable(sender);
        tokenToEthInput(amount, 1, now, _sender, _sender);
    }

    /// @notice Convert tokens to ether. Specify the exact input (in tokens) and
    ///         the minimum output (in ether).
    /// @param tokensSold The exact amount of tokens you want to sell in the
    ///        transaction. Will revert you own less than `minTokens` tokens.
    /// @param minEth The minimum amount of ether you want to receive for the sale
    ///        of `tokensSold` tokens. Will revert if less ether would be received.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @return The amount of ether bought.
    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline)
        external
        returns (uint256)
    {
        return tokenToEthInput(tokensSold, minEth, deadline, msg.sender, msg.sender);
    }

    /// @notice Convert tokens to ether and transfer it to `recipient`.
    ///         Specify the exact input (in tokens) and the minimum output (in ether).
    /// @param tokensSold The exact amount of tokens you want to sell in the
    ///        transaction. Will revert you own less than `minTokens` tokens.
    /// @param minEth The minimum amount of ether you want the `recipient` to receive for
    ///        the sale of `tokensSold` tokens. Will revert if less ether would be transferred.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @param recipient Bought ether will be transferred to this address.
    /// @dev Requirements:
    ///      - `recipient` can't be this contract or the zero address
    /// @return The amount of ether bought.
    function tokenToEthTransferInput(
        uint256 tokensSold,
        uint256 minEth,
        uint256 deadline,
        address payable recipient
    ) external returns (uint256) {
        require(recipient != address(this)); // dev: can't send to liquid token contract
        require(recipient != address(0)); // dev: can't send to zero address
        return tokenToEthInput(tokensSold, minEth, deadline, msg.sender, recipient);
    }


    /// @dev Maximum amount of tokens -> Exact amount of ether
    function tokenToEthOutput(
        uint256 ethBought,
        uint256 maxTokens,
        uint256 deadline,
        address buyer,
        address payable recipient
    ) internal returns (uint256) {
        require(deadline >= now); // dev: deadline passed
        require(ethBought != 0); // dev: must buy more than 0 eth
        uint256 ownedSupply = _ownedSupply;
        uint256 tokenReserve = _totalMinted.sub(_totalBurned + ownedSupply);
        uint256 tokensSold = getOutputPrice(ethBought, tokenReserve, address(this).balance);
        require(maxTokens >= tokensSold); // dev: need more tokens to sell
        _balances[buyer] = _balances[buyer].sub(tokensSold, "LGT: amount exceeds balance");
        _ownedSupply = ownedSupply.sub(tokensSold);
        recipient.call{value: ethBought}("");
        return tokensSold;
    }

    /// @notice Convert tokens to ether. Specify the maximum input (in tokens) and
    ///         the exact output (in ether).
    /// @param ethBought The exact amount of ether you want to receive in the
    ///        transaction. Will revert if tokens can't be sold for enough ether.
    /// @param maxTokens The maximum amount of tokens you are willing to sell to
    ///        receive `ethBought` ether. Will revert if more tokens would be needed.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @return The amount of tokens sold.
    function tokenToEthSwapOutput(uint256 ethBought, uint256 maxTokens, uint256 deadline)
        external
        returns (uint256)
    {
        return tokenToEthOutput(ethBought, maxTokens, deadline, msg.sender, msg.sender);
    }

    /// @notice Convert tokens to ether and transfer it to `recipient`.
    ///         Specify the maximum input (in tokens) and the exact output (in ether).
    /// @param ethBought The exact amount of ether you want `recipient` to receive in the
    ///        transaction. Will revert if tokens can't be sold for enough ether.
    /// @param maxTokens The maximum amount of tokens you are willing to sell to
    ///        buy `ethBought` ether. Will revert if more tokens would be needed.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @param recipient Bought ether will be transferred to this address.
    /// @dev Requirements:
    ///      - `recipient` can't be this contract or the zero address
    /// @return The amount of tokens sold.
    function tokenToEthTransferOutput(
        uint256 ethBought,
        uint256 maxTokens,
        uint256 deadline,
        address payable recipient
    )
        external
        returns (uint256)
    {
        require(recipient != address(this)); // dev: can't send to liquid token contract
        require(recipient != address(0)); // dev: can't send to zero address
        return tokenToEthOutput(ethBought, maxTokens, deadline, msg.sender, recipient);
    }

    // ***** Public Price Functions
    //       --------------------

    /// @notice How many tokens can I buy with `ethSold` ether?
    /// @param ethSold The exact amount of ether you are selling.
    /// @return The amount of tokens that can be bought with `ethSold` ether.
    function getEthToTokenInputPrice(uint256 ethSold) public view returns(uint256) {
        uint256 tokenReserve = _totalMinted.sub(_totalBurned + _ownedSupply);
        return getInputPrice(ethSold, address(this).balance, tokenReserve);
    }

    /// @notice What is the price for `tokensBought` tokens?
    /// @param tokensBought The exact amount of tokens bought
    /// @return The amount of ether needed to buy `tokensBought` tokens
    function getEthToTokenOutputPrice(uint256 tokensBought) public view returns (uint256) {
        uint256 tokenReserve = _totalMinted.sub(_totalBurned + _ownedSupply);
        return getOutputPrice(tokensBought, address(this).balance, tokenReserve);
    }

    /// @notice How much ether do I receive when selling `tokensSold` tokens?
    /// @param tokensSold The exact amount of tokens you are selling.
    /// @return The amount of ether you receive for selling `tokensSold` tokens.
    function getTokenToEthInputPrice(uint256 tokensSold) public view returns (uint256) {
        uint256 tokenReserve = _totalMinted.sub(_totalBurned + _ownedSupply);
        return getInputPrice(tokensSold, tokenReserve, address(this).balance);
    }

    /// @notice How many tokens do I need to sell to receive `ethBought` ether?
    /// @param ethBought The exact amount of ether you are buying.
    /// @return The amount of tokens needed to buy `ethBought` ether.
    function getTokenToEthOutputPrice(uint256 ethBought) public view returns (uint256) {
        uint256 tokenReserve = _totalMinted.sub(_totalBurned + _ownedSupply);
        return getOutputPrice(ethBought, tokenReserve, address(this).balance);
    }
}

// File: LiquidGasToken.sol

/// @title The Liquid Gas Token. An ERC20 Gas Token with integrated liquidity pool.
///        Allows for efficient ownership transfers and lower cost when buying or selling.
/// @author Matthias Nadler
contract LiquidGasToken is LiquidERC20 {

    // ***** Gas Token Core
    //       --------------
    //       Create and destroy contracts

    /// @dev Create `amount` contracts that can be destroyed by this contract.
    ///      Pass _totalMinted as `i`
    function _createContracts(uint256 amount, uint256 i) internal {
        assembly {
            let end := add(i, amount)
            mstore(0,
                add(
                    add(
                        0x746d000000000000000000000000000000000000000000000000000000000000,
                        shl(0x80, address())
                        ),
                    0x3318585733ff6000526015600bf30000
                )
            )
            for {let j := div(amount, 32)} j {j := sub(j, 1)} {
                pop(create2(0, 0, 30, add(i, 0))) pop(create2(0, 0, 30, add(i, 1)))
                pop(create2(0, 0, 30, add(i, 2))) pop(create2(0, 0, 30, add(i, 3)))
                pop(create2(0, 0, 30, add(i, 4))) pop(create2(0, 0, 30, add(i, 5)))
                pop(create2(0, 0, 30, add(i, 6))) pop(create2(0, 0, 30, add(i, 7)))
                pop(create2(0, 0, 30, add(i, 8))) pop(create2(0, 0, 30, add(i, 9)))
                pop(create2(0, 0, 30, add(i, 10))) pop(create2(0, 0, 30, add(i, 11)))
                pop(create2(0, 0, 30, add(i, 12))) pop(create2(0, 0, 30, add(i, 13)))
                pop(create2(0, 0, 30, add(i, 14))) pop(create2(0, 0, 30, add(i, 15)))
                pop(create2(0, 0, 30, add(i, 16))) pop(create2(0, 0, 30, add(i, 17)))
                pop(create2(0, 0, 30, add(i, 18))) pop(create2(0, 0, 30, add(i, 19)))
                pop(create2(0, 0, 30, add(i, 20))) pop(create2(0, 0, 30, add(i, 21)))
                pop(create2(0, 0, 30, add(i, 22))) pop(create2(0, 0, 30, add(i, 23)))
                pop(create2(0, 0, 30, add(i, 24))) pop(create2(0, 0, 30, add(i, 25)))
                pop(create2(0, 0, 30, add(i, 26))) pop(create2(0, 0, 30, add(i, 27)))
                pop(create2(0, 0, 30, add(i, 28))) pop(create2(0, 0, 30, add(i, 29)))
                pop(create2(0, 0, 30, add(i, 30))) pop(create2(0, 0, 30, add(i, 31)))
                i := add(i, 32)
            }

            for { } lt(i, end) { i := add(i, 1) } {
                pop(create2(0, 0, 30, i))
            }
            sstore(_totalMinted_slot, end)
        }
    }

    /// @dev calculate the address of a child contract given its salt
    function computeAddress2(uint256 salt) external view returns (address child) {
        assembly {
            let data := mload(0x40)
            mstore(data,
                add(
                    0xff00000000000000000000000000000000000000000000000000000000000000,
                    shl(0x58, address())
                )
            )
            mstore(add(data, 21), salt)
            mstore(add(data, 53),
                add(
                    add(
                        0x746d000000000000000000000000000000000000000000000000000000000000,
                        shl(0x80, address())
                    ),
                    0x3318585733ff6000526015600bf30000
                )
            )
            mstore(add(data, 53), keccak256(add(data, 53), 30))
            child := and(keccak256(data, 85), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @dev Destroy `amount` contracts and free the gas.
    ///      Pass _totalBurned as `i`
    function _destroyContracts(uint256 amount, uint256 i) internal {
        assembly {
            let end := add(i, amount)

            let data := mload(0x40)
            mstore(data,
                add(
                    0xff00000000000000000000000000000000000000000000000000000000000000,
                    shl(0x58, address())
                )
            )
            mstore(add(data, 53),
                add(
                    add(
                        0x746d000000000000000000000000000000000000000000000000000000000000,
                        shl(0x80, address())
                    ),
                    0x3318585733ff6000526015600bf30000
                )
            )
            mstore(add(data, 53), keccak256(add(data, 53), 30))
            let ptr := add(data, 21)
            for { } lt(i, end) { i := add(i, 1) } {
                mstore(ptr, i)
                pop(call(gas(), keccak256(data, 85), 0, 0, 0, 0, 0))
            }

            sstore(_totalBurned_slot, end)
        }
    }

    // *** Constructor

    // @dev: Set initial liquidity. Must mint at least 1 token to the pool.
    constructor() public {
        _createContracts(1, 0);
    }

    // ***** Gas Token Minting
    //       -----------------
    //       Different ways to mint Gas Tokens


    // *** Mint to owner

    /// @notice Mint personally owned Liquid Gas Tokens.
    /// @param amount The amount of tokens to mint.
    function mint(uint256 amount) external {
        _createContracts(amount, _totalMinted);
        _balances[msg.sender] += amount;
        _ownedSupply += amount;
    }

    /// @notice Mint Liquid Gas Tokens for `recipient`.
    /// @param amount The amount of tokens to mint.
    /// @param recipient The owner of the minted Liquid Gas Tokens.
    function mintFor(uint256 amount, address recipient) external {
        _createContracts(amount, _totalMinted);
        _balances[recipient] += amount;
        _ownedSupply += amount;
    }

    // *** Mint to liquidity pool

    /// @notice Mint Liquid Gas Tokens and add them to the Liquidity Pool.
    ///         The amount of tokens minted and added to the pool is calculated
    ///         from the amount of ether sent and `maxTokens`.
    ///         The liquidity shares are created for the `recipient`.
    ///         Emits an {AddLiquidity} event.
    /// @dev This is much more efficient than minting tokens and adding them
    ///      to the liquidity pool in two separate steps.
    ///      Excess ether that is not added to the pool will be refunded.
    ///      Requirements:
    ///      - `recipient` can't be this contract or the zero address
    /// @param maxTokens The maximum amount of tokens that will be minted.
    ///         Set this to cap the gas the transaction will use.
    ///         If more than maxTokens could be created, the remaining ether is refunded.
    /// @param minLiquidity The minimum amount of liquidity shares to create,
    ///         will revert if not enough liquidity can be created.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @param recipient Liquidity shares are created for this address.
    /// @return tokenAmount Amount of tokens minted and invested.
    /// @return ethAmount Amount of ether invested.
    /// @return liquidityCreated Number of liquidity shares created.
    function mintToLiquidity(
        uint256 maxTokens,
        uint256 minLiquidity,
        uint256 deadline,
        address recipient
    )
        external
        payable
        returns (uint256 tokenAmount, uint256 ethAmount, uint256 liquidityCreated)
    {
        require(deadline >= now); // dev: deadline passed
        require(maxTokens != 0); // dev: can't mint less than 1 token
        require(msg.value != 0); // dev: must provide ether to add liquidity

        // calculate optimum values for tokens and ether to add
        uint256 totalMinted = _totalMinted;
        tokenAmount = maxTokens;
        uint256 tokenReserve = totalMinted.sub(_totalBurned + _ownedSupply);
        uint ethReserve = address(this).balance - msg.value;
        ethAmount = (tokenAmount.mul(ethReserve) / tokenReserve).sub(1);
        if (ethAmount > msg.value) {
            // reduce amount of tokens minted to provide maximum possible liquidity
            tokenAmount = (msg.value + 1).mul(tokenReserve) / ethReserve;
            ethAmount = (tokenAmount.mul(ethReserve) / tokenReserve).sub(1);
        }
        uint256 totalLiquidity = _poolTotalSupply;
        liquidityCreated = ethAmount.mul(totalLiquidity) / ethReserve;
        require(liquidityCreated >= minLiquidity); // dev: not enough liquidity can be created

        // Mint tokens directly to the liquidity pool
        _createContracts(tokenAmount, totalMinted);

        // Create liquidity shares for recipient
        _poolTotalSupply = totalLiquidity + liquidityCreated;
        _poolBalances[recipient] += liquidityCreated;

        emit AddLiquidity(recipient, ethAmount, tokenAmount);

        // refund excess ether
        if (msg.value > ethAmount) {
            msg.sender.call{value: msg.value - ethAmount}("");
        }
        return (tokenAmount, ethAmount, liquidityCreated);
    }

    // *** Mint to sell

    /// @notice Mint Liquid Gas Tokens, immediately sell them for ether and
    ///         transfer the ether to the `recipient`.
    /// @dev This is much more efficient than minting tokens and then selling them
    ///      in two separate steps.
    /// @param amount The amount of tokens to mint and sell.
    /// @param minEth The minimum amount of ether to receive for the transaction.
    ///         Will revert if the tokens don't sell for enough ether;
    ///         The gas for minting is not used.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @return The amount of ether received from the sale.
    function mintToSellTo(
        uint256 amount,
        uint256 minEth,
        uint256 deadline,
        address payable recipient
    )
        public
        returns (uint256)
    {
        require(deadline >= now); // dev: deadline passed
        require(amount != 0); // dev: must sell one or more tokens
        uint256 totalMinted = _totalMinted;
        uint256 tokenReserve = totalMinted.sub(_totalBurned + _ownedSupply);
        uint256 ethBought = getInputPrice(amount, tokenReserve, address(this).balance);
        require(ethBought >= minEth); // dev: tokens not worth enough
        _createContracts(amount, totalMinted);
        recipient.call{value: ethBought}("");
        return ethBought;
    }

    /// @notice Mint Liquid Gas Tokens and immediately sell them for ether.
    /// @dev This is much more efficient than minting tokens and then selling them
    ///      in two separate steps.
    /// @param amount The amount of tokens to mint and sell.
    /// @param minEth The minimum amount of ether to receive for the transaction.
    ///         Will revert if the tokens don't sell for enough ether;
    ///         The gas for minting is not used.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @return The amount of ether received from the sale.
    function mintToSell(
        uint256 amount,
        uint256 minEth,
        uint256 deadline
    )
        external
        returns (uint256)
    {
        return mintToSellTo(amount, minEth, deadline, msg.sender);
    }

    // ***** Gas Token Freeing
    //       -----------------
    //       Different ways to free Gas Tokens


    // *** Free owned tokens

    /// @notice Free `amount` of Liquid Gas Tokens from the `sender`'s balance.
    /// @param amount The amount of tokens to free
    /// @return True if `tokenAmount` tokens could be freed, False otherwise.
    function free(uint256 amount) external returns (bool) {
        uint256 balance = _balances[msg.sender];
        if (balance < amount) {
            return false;
        }
        _balances[msg.sender] = balance - amount;
        _ownedSupply = _ownedSupply.sub(amount);
        _destroyContracts(amount, _totalBurned);
        return true;
    }

    /// @notice Free `amount` of Liquid Gas Tokens from the `owners`'s balance.
    /// @param amount The amount of tokens to free
    /// @param owner The `owner` of the tokens. The `sender` must have an allowance.
    /// @return True if `tokenAmount` tokens could be freed, False otherwise.
    function freeFrom(uint256 amount, address owner) external returns (bool) {
        uint256 balance = _balances[owner];
        if (balance < amount) {
            return false;
        }
        uint256 currentAllowance = _allowances[owner][msg.sender];
        if (currentAllowance < amount) {
            return false;
        }
        _balances[owner] = balance - amount;
        _ownedSupply = _ownedSupply.sub(amount);
        _approve(owner, msg.sender, currentAllowance - amount);
        _destroyContracts(amount, _totalBurned);
        return true;
    }

    // *** Free from liquidity pool

    /// @notice Buy `amount` tokens from the liquidity pool and immediately free them.
    /// @param amount The amount of tokens to buy and free.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @param refundTo Any excess ether will be refunded to this address.
    /// @dev This will not revert unless an unexpected error occurs. Instead it will return 0.
    /// @return The amount of ether spent to buy `amount` tokens.
    function buyAndFree(
        uint256 amount,
        uint256 deadline,
        address payable refundTo
    )
        external
        payable
        returns (uint256)
    {
        if (deadline < now) {
            refundTo.call{value: msg.value}("");
            return 0;
        }
        uint256 totalBurned = _totalBurned;
        uint256 tokenReserve = _totalMinted.sub(totalBurned + _ownedSupply);
        if (tokenReserve < amount) {
            refundTo.call{value: msg.value}("");
            return 0;
        }
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 ethSold = getOutputPrice(amount, ethReserve, tokenReserve);
        if (msg.value < ethSold) {
            refundTo.call{value: msg.value}("");
            return 0;
        }
        uint256 ethRefund = msg.value - ethSold;
        _destroyContracts(amount, totalBurned);
        if (ethRefund != 0) {
            refundTo.call{value: ethRefund}("");
        }
        return ethSold;
    }

    /// @notice Buy as many tokens as possible from the liquidity pool and immediately free them.
    ///         Will buy less than `maxTokens` if not enough ether is provided.
    ///         Excess ether is not refunded!
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @dev Will revert if deadline passed to refund the ether.
    /// @return The amount of tokens bought and freed.
    function buyMaxAndFree(uint256 deadline)
        external
        payable
        returns (uint256)
    {
        require(deadline >= now); // dev: deadline passed
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 totalBurned = _totalBurned;
        uint256 tokenReserve = _totalMinted.sub(totalBurned + _ownedSupply);
        uint256 tokensBought = getInputPrice(msg.value, ethReserve, tokenReserve);
        _destroyContracts(tokensBought, totalBurned);
        return tokensBought;
    }

    // ***** Deployment Functions
    //       ------------------
    //       Execute a deployment while buying tokens and freeing them.


    /// @notice Deploy a contract via create() while buying and freeing `tokenAmount` tokens
    ///         to reduce the gas cost. You need to provide ether to buy the tokens.
    ///         Any excess ether is refunded.
    /// @param tokenAmount The number of tokens bought and freed.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @param bytecode The bytecode of the contract you want to deploy.
    /// @dev Will revert if deadline passed or not enough ether is sent.
    ///      Can't send ether with deployment. Pre-fund the address instead.
    /// @return contractAddress The address where the contract was deployed.

    function deploy(uint256 tokenAmount, uint256 deadline, bytes memory bytecode)
        external
        payable
        returns (address contractAddress)
    {
        require(deadline >= now); // dev: deadline passed
        uint256 totalBurned = _totalBurned;
        uint256 tokenReserve = _totalMinted.sub(totalBurned + _ownedSupply);
        uint256 price = getOutputPrice(tokenAmount, address(this).balance - msg.value, tokenReserve);
        uint256 refund = msg.value.sub(price, "LGT: insufficient ether");
        _destroyContracts(tokenAmount, totalBurned);

        if (refund > 0) {
            msg.sender.call{value: refund}("");
        }
        assembly {
            contractAddress := create(0, add(bytecode, 32), mload(bytecode))
        }
        return contractAddress;
    }

    /// @notice Deploy a contract via create2() while buying and freeing `tokenAmount` tokens
    ///         to reduce the gas cost. You need to provide ether to buy the tokens.
    ///         Any excess ether is refunded.
    /// @param tokenAmount The number of tokens bought and freed.
    /// @param deadline The time after which the transaction can no longer be executed.
    ///        Will revert if the current timestamp is after the deadline.
    /// @param salt The salt is used for create2() to determine the deployment address.
    /// @param bytecode The bytecode of the contract you want to deploy.
    /// @dev Will revert if deadline passed or not enough ether is sent.
    ///      Can't send ether with deployment. Pre-fund the address instead.
    /// @return contractAddress The address where the contract was deployed.
    function create2(uint256 tokenAmount, uint256 deadline, uint256 salt, bytes memory bytecode)
        external
        payable
        returns (address contractAddress)
    {
        require(deadline >= now); // dev: deadline passed
        uint256 totalBurned = _totalBurned;
        uint256 tokenReserve = _totalMinted.sub(totalBurned + _ownedSupply);
        uint256 price = getOutputPrice(tokenAmount, address(this).balance - msg.value, tokenReserve);
        uint256 refund = msg.value.sub(price, "LGT: insufficient ether");
        _destroyContracts(tokenAmount, totalBurned);

        if (refund > 0) {
            msg.sender.call{value: refund}("");
        }
        assembly {
            contractAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        return contractAddress;
    }

    // ***** Advanced Functions !!! USE AT YOUR OWN RISK !!!
    //       -----------------------------------------------
    //       These functions are gas optimized and intended for experienced users.
    //       The function names are constructed to have 3 or 4 leading zero bytes
    //       in the function selector.
    //       Additionally, all checks have been omitted and need to be done before
    //       sending the call if desired.
    //       There are also no return values to further save gas.


    /// @notice Mint Liquid Gas Tokens and immediately sell them for ether.
    /// @dev 3 zero bytes function selector (0x000000079) and removed all checks.
    ///      !!! USE AT YOUR OWN RISK !!!
    /// @param amount The amount of tokens to mint and sell.
    function mintToSell9630191(uint256 amount) external {
        uint256 totalMinted = _totalMinted;
        uint256 ethBought = getInputPrice(
            amount,
            totalMinted.sub(_totalBurned + _ownedSupply),
            address(this).balance
        );
        _createContracts(amount, totalMinted);
        msg.sender.call{value: ethBought}("");
    }

    /// @notice Mint Liquid Gas Tokens, immediately sell them for ether and
    ///         transfer the ether to the `recipient`.
    /// @dev 3 zero bytes function selector (0x00000056) and removed all checks.
    ///      !!! USE AT YOUR OWN RISK !!!
    /// @param amount The amount of tokens to mint and sell.
    /// @param recipient The address the ether is sent to
    function mintToSellTo25630722(uint256 amount, address payable recipient) external {
        uint256 totalMinted = _totalMinted;
        uint256 ethBought = getInputPrice(
            amount,
            totalMinted.sub(_totalBurned + _ownedSupply),
            address(this).balance
        );
        _createContracts(amount, totalMinted);
        recipient.call{value: ethBought}("");
    }


    /// @notice Buy `amount` tokens from the liquidity pool and immediately free them.
    ///         Make sure to pass the exact amount for tokens and sent ether:
    ///             - There are no refunds for unspent ether!
    ///             - Get the exact price by calling getEthToTokenOutputPrice(`amount`)
    ///               before sending the call in the same transaction.
    /// @dev 4 zero bytes function selector (0x00000000) and removed all checks.
    ///      !!! USE AT YOUR OWN RISK !!!
    /// @param amount The amount of tokens to buy and free.
    function buyAndFree22457070633(uint256 amount) external payable {
        uint256 totalBurned = _totalBurned;
        uint256 ethSold = getOutputPrice(
            amount,
            address(this).balance - msg.value,
            _totalMinted.sub(totalBurned + _ownedSupply)
        );
        if (msg.value >= ethSold) {
            _destroyContracts(amount, totalBurned);
        }
    }
}
