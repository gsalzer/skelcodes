// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
import "./INBUNIERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IFeeApprover.sol";
import "./ILCOREVault.sol";
import "./console.sol";
import "./IERC20.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH.sol"; 
import "./Ownable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract NBUNIERC20 is Context, INBUNIERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    event LiquidityAddition(address indexed dst, uint value);
    event LPTokenClaimed(address dst, uint value);

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _initialSupply;
    uint256 public contractStartTimestamp;


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    function initialSetup(address router, address factory, uint256 initialSupply) internal {
        _name = "LinkCore Finance";
        _symbol = "LCORE";
        _decimals = 18;
        _initialSupply = initialSupply;
        _totalsupply_(address(this), initialSupply);
        contractStartTimestamp = block.timestamp;
        uniswapRouterV2 = IUniswapV2Router02(router != address(0) ? router : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapFactory = IUniswapV2Factory(factory != address(0) ? factory : 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    	createUniswapPairMainnet();
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
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    // function balanceOf(address account) public override returns (uint256) {
    //     return _balances[account];
    // }
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }


    IUniswapV2Router02 public uniswapRouterV2;
    IUniswapV2Factory public uniswapFactory;


    address tokenUniswapPair;

    function createUniswapPairMainnet() onlyOwner public returns (address) {
        require(tokenUniswapPair == address(0), "Token: pool already created");
        tokenUniswapPair = uniswapFactory.createPair(
            address(uniswapRouterV2.WETH()),
            address(this)
        );
        return tokenUniswapPair;
    }

    //// Liquidity generation logic
    /// Steps - All tokens tat will ever exist go to this contract
    /// This contract accepts ETH as payable
    /// ETH is mapped to people
    /// When liquidity generationevent is over veryone can call
    /// the LP create function
    // which will put all the ETH and tokens inside the uniswap contract
    /// without any involvement
    /// This LP will go into this contract
    /// And will be able to proportionally be withdrawn baed on ETH put in.
    

    string public liquidityGenerationParticipationAgreement = "I'm not a resident of the United States \n I understand that this contract is provided with no warranty of any kind. \n I agree to not hold the contract creators, team members or anyone associated with this event liable for any damage monetary and otherwise I might onccur. \n I understand that any smart contract interaction carries an inherent risk.";

    function liquidityGenerationOngoing() public view returns (bool) {
        return contractStartTimestamp > block.timestamp;
    }

    uint256 totalLPTokensCreated;
    uint256 totalETHContributed;
    uint256 LPperETHUnit;


    bool public LPGenerationCompleted;
    // Sends all avaibile balances and creates LP tokens
    // Possible ways this could break addressed
    // 1) Multiple calls and resetting amounts - addressed with boolean
    // 2) Failed WETH wrapping/unwrapping addressed with checks
    // 3) Failure to create LP tokens, addressed with checks
    // 4) Unacceptable division errors . Addressed with multiplications by 1e18
    // 5) Pair not set - impossible since its set in constructor
    function addLiquidityToUniswapLCORExWETHPair() public {
        require(liquidityGenerationOngoing() == false, "Liquidity generation onging");
        require(LPGenerationCompleted == false, "Liquidity generation already finished");
        totalETHContributed = address(this).balance;
        IUniswapV2Pair pair = IUniswapV2Pair(tokenUniswapPair);
        console.log("Balance of this", totalETHContributed / 1e18);
        //Wrap eth
        address WETH = uniswapRouterV2.WETH();
        IWETH(WETH).deposit{value : totalETHContributed}();
        require(address(this).balance == 0 , "Transfer Failed");
        IWETH(WETH).transfer(address(pair),totalETHContributed);
        emit Transfer(address(this), address(pair), _balances[address(this)]);
        _balances[address(pair)] = _balances[address(this)];
        _balances[address(this)] = 0;
        pair.mint(address(this));
        totalLPTokensCreated = pair.balanceOf(address(this));
        console.log("Total tokens created",totalLPTokensCreated);
        require(totalLPTokensCreated != 0 , "LP creation failed");
        LPperETHUnit = totalLPTokensCreated.mul(1e18).div(totalETHContributed); // 1e18x for  change
        console.log("Total per LP token", LPperETHUnit);
        require(LPperETHUnit != 0 , "LP creation failed");
        LPGenerationCompleted = true;

    }

    mapping (address => uint)  public ethContributed;
    // Possible ways this could break addressed
    // 1) No ageement to terms - added require
    // 2) Adding liquidity after generaion is over - added require
    // 3) Overflow from uint - impossible there isnt that much ETH aviable
    // 4) Depositing 0 - not an issue it will just add 0 to tally
    function addLiquidity(bool IreadParticipationAgreementInReadSectionAndIagreeFalseOrTrue) public payable {
        require(liquidityGenerationOngoing(), "Liquidity Generation Event over");
        require(IreadParticipationAgreementInReadSectionAndIagreeFalseOrTrue, "No agreement provided");
        ethContributed[msg.sender] += msg.value; // Overflow protection from safemath is not neded here
        totalETHContributed = totalETHContributed.add(msg.value); // for front end display during LGE. This resets with definietly correct balance while calling pair.
        emit LiquidityAddition(msg.sender, msg.value);
    }

    // Possible ways this could break addressed
    // 1) Accessing before event is over and resetting eth contributed -- added require
    // 2) No uniswap pair - impossible at this moment because of the LPGenerationCompleted bool
    // 3) LP per unit is 0 - impossible checked at generation function
    function claimLPTokens() public {
        require(LPGenerationCompleted, "Event not over yet");
        require(ethContributed[msg.sender] > 0 , "Nothing to claim, move along");
        IUniswapV2Pair pair = IUniswapV2Pair(tokenUniswapPair);
        uint256 amountLPToTransfer = ethContributed[msg.sender].mul(LPperETHUnit).div(1e18);
        pair.transfer(msg.sender, amountLPToTransfer); // stored as 1e18x value for change
        ethContributed[msg.sender] = 0;
        emit LPTokenClaimed(msg.sender, amountLPToTransfer);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _totalsupply_(address account, uint256 amount) internal {
     _totalSupply = _totalSupply.add(_initialSupply);
     _balances[account] = _balances[account].add(amount);   
    }
    function setShouldTransferChecker(address _transferCheckerAddress) public onlyOwner {
        transferCheckerAddress = _transferCheckerAddress;
    }

    address public transferCheckerAddress;

    function setFeeDistributor(address _feeDistributor)
        public
        onlyOwner
    {
        feeDistributor = _feeDistributor;
    }

    address feeDistributor;

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
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * This implementation is agnostic to the way tokens are created. This means
     * that a supply mechanism has to be added in a derived contract using {_mint}.
     * For a generic mechanism see {ERC20PresetMinterPauser} documentation.
     * Functions _mint and initialTokensSupply are required to generate initial
     * tokens at the start of the contract. The amount of generated initial tokens 
     * can be checked using totalsupply function in READ section on Etherscan
     */
    function _mint(address ContractAddress, uint256 InitialTokens) internal virtual {
        require(ContractAddress != address(0), "ERC20: Cannot be the zero address");
        _balances[ContractAddress] = _balances[ContractAddress].add(InitialTokens);
    }
    function initialTokensSupply (address ContractAddress, uint256 InitialTokens) public onlyOwner {
        _mint(ContractAddress, InitialTokens);
        LPGenerationCompleted = true;
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. 
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
