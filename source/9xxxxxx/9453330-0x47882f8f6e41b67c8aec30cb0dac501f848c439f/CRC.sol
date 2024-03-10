// File: contracts/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function decimals() external view returns(uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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

// File: contracts/CRC.sol

pragma solidity >=0.5.0 <0.6.0;


//import "./Permissions.sol";
//import "./Exchanger.sol";

contract CRC is IERC20 {
    using SafeMath for uint256;
    using SafeMath for uint32;
    
    event Buy( address account, uint256 amount, uint32 coin_id, uint256 coin_amount );
    event Sell( address account, uint256 amount, uint32 coin_id, uint256 coin_amount  );
    event PermissionSet(address indexed sender, address indexed to, uint8 permission);


    struct Coin {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        uint32 rate;
        uint32 spread;
        uint8 status;
        uint32 min_rate;
        uint32 max_rate;
        uint32 max_spread;
    }

    // Permissions 
    mapping(address=>uint8) _permissions;
    // ERC20 data
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address=>address) public referrals;


    mapping (uint16=>Coin) _coins;
    mapping (address=>uint16) _coin_index;
    
    uint256 public rounding = 2;
    uint256 public INITIAL_SUPPLY = 1000 * 10**18;

    uint256 percentPrecision = 10 ** 12;
    uint256 percentPerMinute = 36 * percentPrecision / (365 * 24 * 60);
    uint32 transfer_fee = 10;
    uint32 referral_fee = 20000;

    uint256 referral_deposit = 0;
    uint256 public INITIAL_TIME = 0;
    uint256 private _totalSupply;

    uint8 _initialized = 0;

    // Exchanger data
    uint32 rate_precision = 10000;
    uint16 _coin_counter=1;




    function isOwner() public view returns (bool) {
        return _permissions[msg.sender] & 1 != 0;
    }

    function isOperator() public view returns (bool) {
        return _permissions[msg.sender] & 2 != 0;
    }

    function isOwnerOrOperator() public view returns (bool) {
        return _permissions[msg.sender] & 3 != 0;
    }

    modifier onlyOwner() {
        require(isOwner(), "Permission: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(isOperator(), "Permission: caller is not the operator");
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(isOwnerOrOperator(), "Permission: caller is not the owner or operator");
        _;
    }

    function renounceOwnership() public onlyOwner {
        _permissions[msg.sender] &= 0xFE;
        emit PermissionSet(msg.sender, msg.sender, _permissions[msg.sender]);
    }

    function _setPermission(address _to, uint8 _permission) internal {
        _permissions[_to] = _permission;
        emit PermissionSet(msg.sender, _to, _permission);

    }

    function setPermission(address _to, uint8 _permission) public onlyOwner {
        _setPermission(_to, _permission);
    }
 
    // CRC 
    function name() public view returns(string memory){
        require(_initialized > 0, "Not initialized");
        return "CRC Stable Coin";
    }

    function symbol() public view returns(string memory){
        require(_initialized > 0, "Not initialized");
        return "CRC";
    }

    function decimals() public view returns(uint8){
        require(_initialized > 0, "Not initialized");
        return 18;
    }

    function getInitialTime() public view returns(uint256) {
        return INITIAL_TIME;
    }

    function balanceChange(address account) private view returns (uint256){
        return _balances[account].div(percentPrecision.mul(100)).mul(percentPerMinute).mul( block.timestamp.sub(INITIAL_TIME).div(60) );
    }

    function totalSupplyChange() private view returns (uint256){
        return _totalSupply.div(percentPrecision.mul(100)).mul(percentPerMinute).mul( block.timestamp.sub(INITIAL_TIME).div(60) );
    }


    function equalizedAmount(uint256 amount) public view returns (uint256){
        return amount.div( block.timestamp.sub(INITIAL_TIME).div(60).mul(percentPerMinute).add( percentPrecision.mul(100) )).mul(percentPrecision.mul(100));
    }



    function round(uint256 amount) public pure returns (uint256){
        uint256 rounded = amount.div(10**16).mul(10**16);
        if(amount.sub(rounded) > 99 * 10**14){
            rounded += 10**16;
        }
        return rounded;
    }

    // ERC20

    function balanceOf(address account) public view returns (uint256){
        return round(_balances[account].add(balanceChange(account)));
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply.add(totalSupplyChange());
    }


    function transfer(address recipient, uint256 amount) public returns (bool) {
        uint256 commission = amount.mul(transfer_fee).div(10000);
        _transfer(msg.sender, recipient, amount.sub(commission));
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 commission = amount.mul(transfer_fee).div(10000);
        _transfer(sender, recipient, amount.sub(commission));
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 token_amount = equalizedAmount(amount);
        _balances[sender] = _balances[sender].sub(token_amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(token_amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        uint256 token_amount = equalizedAmount(amount);
        _totalSupply = _totalSupply.add(token_amount);
        _balances[account] = _balances[account].add(token_amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 token_amount = equalizedAmount(amount);
        _balances[account] = _balances[account].sub(token_amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(token_amount);
        emit Transfer(account, address(0), amount);
    }
 
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        uint256 token_amount = equalizedAmount(amount);
        _burn(account, token_amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    // Exchanger


    function buyref(uint16 coin_id, uint256 amount, address referral) public returns (bool) {
        require(_coins[coin_id].status & 1 != 0, "Coin in not active");
        uint256 coin_amount = amount;
        if(amount == 0){
            coin_amount = IERC20(_coins[coin_id].token).allowance(msg.sender, address(this));
        }
        require(coin_amount > 0, "No funds avaialble");
        IERC20(_coins[coin_id].token).transferFrom(msg.sender, address(this), coin_amount);
        uint256 current_token_amount = getBuyCoinAmountByID(coin_id, coin_amount);
        uint256 token_amount = equalizedAmount(current_token_amount);
        _mint(msg.sender, token_amount);
        if( referral != address(0) && referral_fee > 0 && balanceOf(referral) >= referral_deposit ){
            if( referrals[msg.sender] == address(0) ){
                referrals[msg.sender] = referral;
            }
            _mint(referral, token_amount.mul(coinGetSpread(coin_id)).div(20000));
        }else{
            if( referrals[msg.sender] != address(0) && referral_fee > 0 && balanceOf(referrals[msg.sender]) >= referral_deposit ){
                _mint(referrals[msg.sender], token_amount.mul(coinGetSpread(coin_id)).div(referral_fee));
            }
        }
        emit Buy(msg.sender, current_token_amount, coin_id, amount);

        return true;
    }

    function buy(uint16 coin_id, uint256 amount) public returns (bool) {
        require(_coins[coin_id].status & 1 != 0, "Coin in not active");
        uint256 coin_amount = amount;
        if(amount == 0){
            coin_amount = IERC20(_coins[coin_id].token).allowance(msg.sender, address(this));
        }
        require(coin_amount > 0, "No funds avaialble");
        IERC20(_coins[coin_id].token).transferFrom(msg.sender, address(this), coin_amount);
        uint256 current_token_amount = getBuyCoinAmountByID(coin_id, coin_amount);
        uint256 token_amount = equalizedAmount(current_token_amount);
        _mint(msg.sender, token_amount);
        if( referrals[msg.sender] != address(0) && referral_fee > 0 && balanceOf(referrals[msg.sender]) >= referral_deposit ){
                _mint(referrals[msg.sender], token_amount.mul(coinGetSpread(coin_id)).div(referral_fee));
        }
        emit Buy(msg.sender, current_token_amount, coin_id, amount);
        return true;
    }


    function sell(uint16 coin_id, uint256 amount) public returns (bool) {
        require(_coins[coin_id].status & 2 != 0, "Coin in not active");
        _burn(msg.sender, equalizedAmount(amount));
        uint256 coin_amount = getSellTokenAmountByID(coin_id, amount);
        IERC20(_coins[coin_id].token).transfer(msg.sender, coin_amount);
        emit Sell(msg.sender, amount, coin_id, coin_amount);
        return true;
    }

    function setTransferFee(uint32 _transfer_fee) public onlyOwner returns(bool){
        transfer_fee = _transfer_fee;
        return true;
    }

    function setReferralFee(uint32 _referral_fee) public onlyOwner returns(bool){
        referral_fee = _referral_fee;
        return true;
    }

    function setReferralDeposit(uint32 _referral_deposit) public onlyOwner returns(bool){
        referral_deposit = _referral_deposit;
        return true;
    }


    function addCoin(address _token, string memory _name, string memory _symbol, uint8 _decimals) public onlyOwner returns(bool){
        _coins[_coin_counter] = Coin(_token, _name, _symbol, _decimals, 1*rate_precision, 0, 0, 9000, 11000, 1000);
        _coin_index[_token] = _coin_counter;
        _coin_counter += 1;
    }

    function fetchCoin(address _token) public onlyOwner returns(bool){
        string memory _name = IERC20(_token).name();
        string memory _symbol = IERC20(_token).symbol();
        uint8 _decimals = IERC20(_token).decimals();

        _coins[_coin_counter] = Coin(_token, _name, _symbol,  _decimals, 1 * rate_precision, 0, 0, 9000, 11000, 1000);
        _coin_index[_token] = _coin_counter;
        _coin_counter += 1;

    }


    function setStatusByID(uint16 coin_id, uint8 status) public onlyOwner returns(bool){
        _coins[coin_id].status = status;
        return true;
    }

    function setRateLimitsByID(uint16 coin_id, uint32 min_rate, uint32 max_rate, uint32 max_spread) public onlyOwner returns(bool){
        require(min_rate <= max_rate, "Invalid rate");
        _coins[coin_id].min_rate = min_rate;
        _coins[coin_id].max_rate = max_rate;
        _coins[coin_id].max_spread = max_spread;
        if( _coins[coin_id].rate < min_rate  ){
            _coins[coin_id].rate = min_rate;
        }
        if( _coins[coin_id].rate > max_rate  ){
            _coins[coin_id].rate = max_rate;
        }
        if( _coins[coin_id].spread > max_spread  ){
            _coins[coin_id].spread = max_spread;
        }
        return true;
    }


    function setRateByID(uint16 coin_id, uint32 rate) public onlyOwnerOrOperator returns(bool){
        require(rate >= _coins[coin_id].min_rate && rate <= _coins[coin_id].max_rate, "Rate out of limits");
        _coins[coin_id].rate = rate;
        return true;
    }

    function setSpreadByID(uint16 coin_id, uint32 spread) public onlyOwnerOrOperator returns(bool){
        require(spread <= _coins[coin_id].max_spread, "Spread out of limits");
        _coins[coin_id].spread = spread;
        return true;
    }

    function transferCoinByID(uint16 coin_id, address to, uint256 amount) public onlyOwner returns(bool){
        IERC20(_coins[coin_id].token).transfer(to, amount);
        return true;
    }

    function balanceOfCoin(uint16 coin_id) public view returns(uint256){
        return IERC20(_coins[coin_id].token).balanceOf(address(this));
    }

    function coinCounter() public view returns(uint16){
        return _coin_counter;
    }

    function coin(uint16 index) public view returns(string memory coinName, string memory coinSymbol, uint8 coinDecimals){
        return (_coins[index].name, _coins[index].symbol, _coins[index].decimals);
    }

    function coinRate(uint16 index) public view returns(uint32 rate, uint32 spread){
        return (_coins[index].rate, _coins[index].spread);
    }

    function coinRateLimits(uint16 index) public view returns(uint32 min_rate,uint32 max_rate, uint32 max_spread){
        return (_coins[index].min_rate,_coins[index].max_rate,_coins[index].max_spread);
    }


    function coinGetRate(uint16 index) public view returns(uint32){
        return _coins[index].rate;
    }

    function coinGetSpread(uint16 index) public view returns(uint32){
        return _coins[index].spread;
    }

    function coinGetStatus(uint16 index) public view returns(uint8){
        return _coins[index].status;
    }

    function coinData(uint16 index) public view returns(address coinAddress, uint8 coinStatus){
        return (_coins[index].token, _coins[index].status);
    }

    function normalizeCoinAmount(uint256 amount, uint8 coin_decimals ) internal pure returns (uint256){
        if( coin_decimals > 18 ){
            return amount.div(uint256(10) ** (coin_decimals-18));
        }
        return amount.mul(uint256(10) ** (18-coin_decimals));
    }

    function normalizeTokenAmount(uint256 amount, uint8 coin_decimals ) internal pure returns (uint256){
        if( coin_decimals >= 18 ){
            return amount.mul(uint256(10) ** (coin_decimals-18));
        }
        return amount.div(uint256(10) ** (18-coin_decimals));
    }

        function getSellTokenAmountByID(uint16 coin_id, uint256 amount) public view returns(uint256){
        return normalizeTokenAmount(amount.div(_coins[coin_id].rate.add(_coins[coin_id].spread)).mul(rate_precision), _coins[coin_id].decimals);
    }

    function getBuyTokenAmountByID(uint16 coin_id, uint256 amount) public view returns(uint256){
        return normalizeTokenAmount(amount.div(_coins[coin_id].rate.sub(_coins[coin_id].spread)).mul(rate_precision), _coins[coin_id].decimals);
    }

    function getSellCoinAmountByID(uint16 coin_id, uint256 amount) public view returns(uint256){
        return normalizeCoinAmount(amount.mul(_coins[coin_id].rate.add(_coins[coin_id].spread)).div(rate_precision), _coins[coin_id].decimals);
    }

    function getBuyCoinAmountByID(uint16 coin_id, uint256 amount) public view returns(uint256){
        return normalizeCoinAmount(amount.mul(_coins[coin_id].rate.sub(_coins[coin_id].spread)).div(rate_precision), _coins[coin_id].decimals);
    }

    function getBuyTokenAmount(address coin_address, uint256 amount) public view returns(uint256){
        return getBuyTokenAmountByID(_coin_index[coin_address], amount);
    }
    function getSellTokenAmount(address coin_address, uint256 amount) public view returns(uint256){
        return getSellTokenAmountByID(_coin_index[coin_address], amount);
    }

    function getBuyCoinAmount(address coin_address, uint256 amount) public view returns(uint256){
        return getBuyCoinAmountByID(_coin_index[coin_address], amount);
    }
    function getSellCoinAmount(address coin_address, uint256 amount) public view returns(uint256){
        return getSellCoinAmountByID(_coin_index[coin_address], amount);
    }

    // Initialization 

    function initialize() public returns(bool){
        require(_initialized == 0, "Already initialized");
        _initialized = 1;
        rounding = 2;
        INITIAL_SUPPLY = 1000 * 10**18;
        INITIAL_TIME = block.timestamp.sub(365*24*60*60);
        percentPrecision = 10 ** 12;
        percentPerMinute = 36 * percentPrecision / (365 * 24 * 60);
        transfer_fee = 10;
        referral_fee = 20000;
        _setPermission(msg.sender, 3);
        _mint(msg.sender, INITIAL_SUPPLY);

        rate_precision = 10000;
        _coin_counter = 1;

        return true;
    }



}
