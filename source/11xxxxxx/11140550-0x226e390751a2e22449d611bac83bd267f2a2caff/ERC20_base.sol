// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??

pragma solidity ^0.6.6;
 import "./STVKE_lib.sol";

contract ERC20_base is Context {

    using SafeMath for uint256;
    using Address for address;


    struct FEES {
    uint256  _burnOnTX;
    uint256  _feeOnTX;
    address  _feeDest;
    }
    FEES private Fees;
    

    struct BURNMINT {
    bool  _burnable;
    bool  _mintable;
    uint256 _cappedSupply;
    }
    BURNMINT private BurnMint;

    struct GOV {
    address  _owner;
    bool  _basicGovernance;
    uint256  _noTransferTimeLock;  //transfers KO before this time
    }
    GOV private Gov;
    
    
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

//Events

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

    event Log(string log);
    
//ERC20 MODIFIERS
    modifier onlyOwner() {
        require(Gov._owner == msg.sender, "onlyOwner");
        _;
    }


//Constructor
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol, uint8 decimals, 
                uint256 supply, address mintDest,
                uint256 BurnMintGov, uint256 burnOnTX,
                uint256 cappedSupply,
                uint256 feeOnTX, address feeDest,
                uint256 noTransferTimeLock,
                address owner) public {
        
        
        //ERC20
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        
        //FEES
              
        Fees._feeOnTX = feeOnTX; //base 10000
        Fees._feeDest = feeDest;
        if(feeOnTX >  0){require(feeDest != address(0), "fee cannot be sent to 0x0");}
        
        
        //BURN-MINT-GOV
        
        //BurnMintGov = 000, 001, 101...
        uint256 _remainder;
        if(BurnMintGov >= 100){ 
            BurnMint._burnable = true;
            _remainder = BurnMintGov.sub(100);
        }

        
        if(BurnMintGov >= 10){ 
            BurnMint._mintable = true;
            _remainder = BurnMintGov.sub(10);
        }

        if(BurnMintGov >= 1){ Gov._basicGovernance = true;}


        Fees._burnOnTX = burnOnTX; //base 10000, 0.01% = 1
        if(!BurnMint._burnable){Fees._burnOnTX = 0;} //avoid users to create non burnable tokens with a burnOnTX
        

        BurnMint._cappedSupply = cappedSupply;
  
        //GOV
        Gov._owner = owner;
        Gov._noTransferTimeLock = noTransferTimeLock.add(block.timestamp);
        
        //mints!!
        if(mintDest == address(0)){mintDest = msg.sender;}
        
        //low level mint for token creation
        require(mintDest != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(supply);
        _balances[mintDest] = _balances[mintDest].add(supply);
        emit Transfer(address(0), mintDest, supply); //minted event.
    }

//Public Functions
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
    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


//Internal Functions
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

        require(block.timestamp > Gov._noTransferTimeLock, "Transfers blocked for the moment");
        _beforeTokenTransfer(sender, recipient, amount);
        
        uint256 _fee = 0; uint256 _burnFee = 0;
        
        if(Fees._feeOnTX > 0){
            _fee = amount.mul(Fees._feeOnTX).div(10000);
            _balances[sender] = _balances[sender].sub(_fee, "ERC20: transfer amount exceeds balance");
            _balances[Fees._feeDest] = _balances[Fees._feeDest].add(_fee);
            emit Transfer(sender,Fees._feeDest,_fee);
        }
        if(Fees._burnOnTX > 0){
            _burnFee = amount.mul(Fees._burnOnTX).div(10000);
            _burn(sender, _burnFee); //only if _burnable = true
        }
        
        
        uint256 netAmount = amount.sub(_fee).sub(_burnFee);
        _balances[sender] = _balances[sender].sub(netAmount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(netAmount);
        
        emit Transfer(sender, recipient, netAmount);
    }  


    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     * - cannot exceed 'capped supply'.
     * - token must be 'mintable'.
     * - must be sent by 'owner'.
     */
    function mint(uint256 amount) external virtual onlyOwner {
        require(BurnMint._mintable, "token NOT mintable");
        require(_totalSupply.add(amount) <= BurnMint._cappedSupply || BurnMint._cappedSupply == 0);
        require(_msgSender() != address(0), "ERC20: mint to the zero address");
        
        _mint(_msgSender(), amount);
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
        require(BurnMint._mintable, "token NOT mintable");
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
    function _burn(address account, uint256 amount) internal virtual {
        require(BurnMint._burnable, "token NOT burnable");
        
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
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual returns(uint256 netAmount) {
    }

//basic Governance & getters

function setBurnFee(uint256 _newFee) public onlyOwner {
    require(_newFee <= 2000, "Max burnFee capped at 20%");
    require(Gov._basicGovernance, "Basic governance not enabled");
    Fees._burnOnTX = _newFee;
}
function viewBurnOnTX() public view returns(uint256){
    return Fees._burnOnTX;
}

function setFee(uint256 _newFee) public onlyOwner{
    require(_newFee <= 2000, "Max Fee capped at 20%");
    require(Gov._basicGovernance, "Basic governance not enabled");
    Fees._feeOnTX = _newFee;
}
function viewFeeOnTX() public view returns(uint256){
    return Fees._feeOnTX;
}

function setFeeDest(address feeDest) external onlyOwner {
    require(Gov._basicGovernance, "Basic governance not enabled");
    Fees._feeDest = feeDest;
}
function viewFeeDest() public view returns(address){
    return Fees._feeDest;
}

function setOwnerShip(address _address) public onlyOwner {
    require(Gov._basicGovernance, "Basic governance not enabled");
    require(Gov._owner != address(0));
    Gov._owner = _address;
}

function revokeOwnerShip() public onlyOwner {
    require(Gov._basicGovernance, "Basic governance not enabled");
    Gov._owner = address(0);
}

function viewIfBurnable() public view returns(bool) {
    return BurnMint._burnable;   
}

function viewIfMintable() public view returns(bool) {
    return BurnMint._mintable;
}

function revokeMinting() public onlyOwner {
    require(BurnMint._mintable, "Minting not enabled");
    BurnMint._mintable = false;
}

function viewCappedSupply() public view returns(uint256) {
    return BurnMint._cappedSupply;
}

function viewOwner() public view returns(address) {
    return Gov._owner;
}
    
} 
