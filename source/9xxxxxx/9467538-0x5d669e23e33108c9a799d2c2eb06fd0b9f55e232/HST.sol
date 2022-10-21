pragma solidity ^0.5.1;
contract EIP20NonStandardInterface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public;

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract ERC20 is IERC20,Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
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
    function mint(address account, uint256 amount) public onlyOwner returns (bool){
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        return true;
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
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}
contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
}
contract HST is ERC20, ERC20Detailed,DSMath {

    mapping (address => bytes32) public refs;
    mapping (bytes32 => address) public _refs;
    mapping (address => uint256) public lock1;
    mapping (address => uint256) public lock2;
    mapping (address => uint256) public repurchase;
    address public usdtContractAddress;
    uint256 public totalSell=0; 
    
    uint256 public startSelltime = block.timestamp;
    uint256 public lock1time = startSelltime + 30 days;
    uint256 public lock2time = startSelltime + 60 days;

    address IEOOwner = 0x5B15a5c77c38909a05be5b9F3F461ebfd146aF6A;

    struct Player {
        uint256 stake;    // 总质押总数
        uint256 payout;    // 
        uint256 total_out;    // 已经领取的分红
    }
    mapping (address => Player) public plyr_;   // (player => data) player data   

    struct Global {
        uint256 total_stake;    // 总质押总数
        uint256 total_out;    //  总分红金额
        uint256 earnings_per_share;    // 每股分红
    }
    mapping (uint256 => Global) public global_;   // (global => data) global data

    struct UnstakeTable{
        uint256 amount;
        uint256 unlockTime;
    }
    mapping (address => UnstakeTable) public unstake_;  //每个人解锁的代币以及时间
    uint256 waitTime = 10 days; //unstake后，10天才能取回
    
    event Buytoken(address indexed _buy, address indexed _ref, uint256 _value);
    event Unlock1(address indexed _from, uint256 _value);
    event Unlock2(address indexed _from, uint256 _value);

    event Stake(address indexed _from, uint256 _value);
    event Unstake(address indexed _from, uint256 _value,uint256 _type);
    event Claim(address indexed _from, uint256 _value);
    event Ref(address indexed _ref, address indexed _who,uint256 _value);
    event Addprofit(uint256 _value);
    
    IERC20  private usdtContract;
    
    constructor () public ERC20Detailed("Happy Store Token", "HST", 6){
        super.mint(address(this), 100000000 * (10 ** uint256(decimals())));
        usdtContractAddress = address(0xdAC17F958D2ee523a2206206994597C13D831ec7); 
    }
    
    function stake(uint256 amount) public{
        super._transfer(msg.sender,address(this),amount);
        plyr_[msg.sender].stake = plyr_[msg.sender].stake.add(amount);
        if (global_[0].earnings_per_share == 0){
            plyr_[msg.sender].payout = 0;
        }else{
            plyr_[msg.sender].payout = plyr_[msg.sender].payout.add(
                wmul(global_[0].earnings_per_share,amount)
                );
        }
        global_[0].total_stake = global_[0].total_stake.add(amount);
        emit Stake(msg.sender,amount);
    }
    function unstake(uint256 amount) public{
        claim();
        plyr_[msg.sender].payout = plyr_[msg.sender].payout.sub(
            wmul(global_[0].earnings_per_share,amount)
        );
        plyr_[msg.sender].stake = plyr_[msg.sender].stake.sub(amount);
        global_[0].total_stake = global_[0].total_stake.sub(amount);
        emit Unstake(msg.sender,amount,0);

        unstake_[msg.sender].unlockTime = block.timestamp + waitTime;
        unstake_[msg.sender].amount = unstake_[msg.sender].amount.add(amount);

    }
    function unstake_token() public {
        require(block.timestamp > unstake_[msg.sender].unlockTime,"not time");
        require(unstake_[msg.sender].amount>0,"no token");
        uint256 out = unstake_[msg.sender].amount;
        unstake_[msg.sender].amount = 0;
        super._transfer(address(this),msg.sender,out);
        emit Unstake(msg.sender,out,1);
    }
    function claim() public{
        uint256 out = cal_out(msg.sender);
        plyr_[msg.sender].payout =  wmul(global_[0].earnings_per_share,plyr_[msg.sender].stake);
        plyr_[msg.sender].total_out = plyr_[msg.sender].total_out.add(out);
        if (out >0){
            dotransfer(msg.sender,out);
            emit Claim(msg.sender,out);
        }
    }
    function make_profit(uint256 amount) public{
        emit Addprofit(amount);
        dotransferFrom(msg.sender,address(this),amount); //usdt转给合约...
        global_[0].earnings_per_share = global_[0].earnings_per_share.add(wdiv(amount,global_[0].total_stake));
        global_[0].total_out = global_[0].total_out.add(amount);
    }
    function cal_out(address user) public view returns(uint256){
        uint256 _cal = wmul(global_[0].earnings_per_share,plyr_[user].stake);
        if (_cal < plyr_[user].payout){
            return 0;
        }else{
            return _cal.sub(plyr_[user].payout);
        }
    }
    function setUsdtContractAddress(address _address) public onlyOwner{
        usdtContractAddress = _address;
    }
    
    function buytoken(uint256 _amount,bytes32 _ref) public {
        
        dotransferFrom(msg.sender,IEOOwner,_amount); 

        //sell token
        uint256 selltoken = _amount.mul(50);//1usdt=50hst
        totalSell = totalSell.add(selltoken);
        uint256 locktoken = selltoken.mul(40).div(100); //40%
        
        lock1[msg.sender] = lock1[msg.sender].add(locktoken);
        lock2[msg.sender] = lock2[msg.sender].add(locktoken);
        repurchase[msg.sender] = repurchase[msg.sender].add(selltoken);
        super._transfer(address(this),msg.sender,selltoken.mul(20).div(100)); //20%
        address refaddress = _refs[_ref];
        if (refaddress != address(0)){
            uint256 refAmount = selltoken.mul(5).div(100);
            emit Ref(address(refaddress),msg.sender,refAmount);
            super._transfer(address(this),address(refaddress),refAmount);
        }
        
        emit Buytoken(msg.sender,refaddress,selltoken);
        
        
    }
    function dotransferFrom(address from,address to,uint256 amount) private {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(usdtContractAddress);
        bool result;

        token.transferFrom(from, to, amount);
        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    result := not(0)          // set result to true
                }
                case 32 {                     // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    result := mload(0)        // Set `result = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(result,"error");
    }
    function dotransfer(address to,uint256 amount) private {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(usdtContractAddress);
        bool result;

        token.transfer(to, amount);
        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    result := not(0)          // set result to true
                }
                case 32 {                     // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    result := mload(0)        // Set `result = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(result,"error");
    }

    
    
    function registere(bytes32 ref) public{
        require(ref != bytes32(0),"no 0");
        if (_refs[ref] != address(0)){
            require(false,"Name already exists");
        }
        if (refs[msg.sender] != bytes32(0)){
            require(false,"Already registered");
        }
        refs[msg.sender] = ref;
        _refs[ref] = msg.sender;
    }
    
    function unlockToken(int8 _type) public {
        if (_type == 1){
            //lock1
            require(lock1[msg.sender]>0,"error");
            require(block.timestamp>lock1time,"no the time");
            uint256 unlockTokenAmount = lock1[msg.sender];
            lock1[msg.sender] = 0;
            super._transfer(address(this),msg.sender,unlockTokenAmount);
            emit Unlock1(msg.sender,unlockTokenAmount);
            
            
        }else if (_type == 2){
            //lock2
            require(lock2[msg.sender]>0,'error');
            require(block.timestamp>lock2time,"no the time");
            uint256 unlockTokenAmount = lock2[msg.sender];
            lock2[msg.sender] = 0;
            super._transfer(address(this),msg.sender,unlockTokenAmount);
            emit Unlock2(msg.sender,unlockTokenAmount);
        }else{
            require(false,"error");
        }
        
        
    }
    
    function transderAnyToken(address tokenAddress,address to,uint256 amount) onlyOwner public{
        EIP20NonStandardInterface token = EIP20NonStandardInterface(tokenAddress);
        token.transfer(to, amount);
    }
}
