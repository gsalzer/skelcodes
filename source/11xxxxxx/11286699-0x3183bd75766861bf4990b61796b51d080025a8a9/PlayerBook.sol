// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.6.0;

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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity ^0.6.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/library/NameFilter.sol

pragma solidity  0.6.12;

library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.  
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x 
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string memory _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
        // create a bool to track if we have a non number character
        bool _hasNonNumber;
        
        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint8(_temp[i]) + 32);
                
                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                
                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

// File: contracts/library/Governance.sol

pragma solidity  0.6.12;

contract Governance {

    address public _governance;

    constructor() public {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }


}

// File: contracts/interface/IPlayerBook.sol

pragma solidity  0.6.12;


interface IPlayerBook {
    function settleReward( address from,uint256 amount ) external returns (uint256);
    function bindRefer( address from,string calldata  affCode ) external  returns (bool);
    function hasRefer(address from)  external returns(bool);
    function getPlayerLaffAddress(address from) external returns(address); 

}

// File: contracts/PlayerBook.sol

pragma solidity  0.6.12;

// import '@openzeppelin/contracts/ownership/Ownable.sol';


// import "../library/SafeERC20.sol";



contract PlayerBook is Governance {
    using NameFilter for string;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
 
    // register pools       
    mapping (address => bool) public _pools;

    // (addr => pID) returns player id by address
    mapping (address => uint256) public _pIDxAddr;   
    // (name => pID) returns player id by name      
    mapping (bytes32 => uint256) public _pIDxName;    
    // (pID => data) player data     
    mapping (uint256 => Player) public _plyr;      
    // (pID => name => bool) list of names a player owns.  (used so you can change your display name amoungst any name you own)        
    mapping (uint256 => mapping (bytes32 => bool)) public _plyrNames; 
  
    // total number of players
    uint256 public _pID;
    // total register name count
    uint256 public _totalRegisterCount = 0;

    // the direct refer's reward rate  直接推荐人的奖励率
    uint256 public _referRewardRate = 1000; //10%
    // base rate
    uint256 public _baseRate = 10000;

    // base price to register a name
    uint256 public _registrationBaseFee = 10 finney;     
    // register fee count step
    uint256 public _registrationStep = 100;
    // add base price for one step
    uint256 public _stepFee = 10 finney;     

    bytes32 public _defaulRefer = "hbt";

    address payable public _teamWallet;
  
    struct Player {
        address addr;
        bytes32 name;
        uint8 nameCount;
        uint256 laff;
        uint256 lvCount;
    }

    event eveBindRefer(uint256 pID, address addr, bytes32 name, uint256 affID, address affAddr, bytes32 affName);
    event eveDefaultPlayer(uint256 pID, address addr, bytes32 name);      
    event eveNewName(uint256 pID, address addr, bytes32 name, uint256 affID, address affAddr, bytes32 affName, uint256 balance  );
    event eveAddPool(address addr);
    event eveRemovePool(address addr);


    constructor(address payable teamWallet)
        public
    {
        _pID = 0;
        _teamWallet = teamWallet;
        addDefaultPlayer(_teamWallet,_defaulRefer);
    }

    /**
     * check address
     */
    modifier validAddress( address addr ) {
        require(addr != address(0x0));
        _;
    }

    /**
     * check pool
     */
    modifier isRegisteredPool(){
        require(_pools[msg.sender],"invalid pool address!");
        _;
    }

    // only function for creating additional rewards from dust
    function seize(IERC20 asset) external returns (uint256 balance) {
        balance = asset.balanceOf(address(this));
        asset.safeTransfer(_teamWallet, balance);
    }

    // get register fee 
    function seizeEth() external  {
        uint256 _currentBalance =  address(this).balance;
        _teamWallet.transfer(_currentBalance);
    }
    
    /**
     * revert invalid transfer action
     */
    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }

    /**
     * registe a pool
     */
    function addPool(address poolAddr)
        onlyGovernance
        public
    {
        require( !_pools[poolAddr], "derp, that pool already been registered");

        _pools[poolAddr] = true;

        emit eveAddPool(poolAddr);
    }
    
    /**
     * remove a pool
     */
    function removePool(address poolAddr)
        onlyGovernance
        public
    {
        require( _pools[poolAddr], "derp, that pool must be registered");

        _pools[poolAddr] = false;

        emit eveRemovePool(poolAddr);
    }

    /**
     * check name string
     * 查询某个名字是否可以注册
     */
    function checkIfNameValid(string memory nameStr)
        public
        view
        returns(bool)
    {
        bytes32 name = nameStr.nameFilter();
        if (_pIDxName[name] == 0)
            return (true);
        else 
            return (false);
    }
    
    /**
     * @dev add a default player
     */
    function addDefaultPlayer(address addr, bytes32 name)
        private
    {        
        _pID++;

        _plyr[_pID].addr = addr;
        _plyr[_pID].name = name;
        _plyr[_pID].nameCount = 1;
        _pIDxAddr[addr] = _pID;
        _pIDxName[name] = _pID;
        _plyrNames[_pID][name] = true;

        //fire event
        emit eveDefaultPlayer(_pID,addr,name);        
    }
    
    /**
     * @dev set refer reward rate
     */
    function setReferRewardRate(uint256 referRate) public  
        onlyGovernance
    {
        _referRewardRate = referRate;
    }

    /**
     * @dev set registration step count
     */
    function setRegistrationStep(uint256 registrationStep) public  
        onlyGovernance
    {
        _registrationStep = registrationStep;
    }

    /**
     * @dev registers a name.  UI will always display the last name you registered.
     * but you will still own all previously registered names to use as affiliate 
     * links.
     * - must pay a registration fee.
     * - name must be unique
     * - names will be converted to lowercase
     * - cannot be only numbers
     * - cannot start with 0x 
     * - name must be at least 1 char
     * - max length of 32 characters long
     * - allowed characters: a-z, 0-9
     * -functionhash- 0x921dec21 (using ID for affiliate)
     * -functionhash- 0x3ddd4698 (using address for affiliate)
     * -functionhash- 0x685ffd83 (using name for affiliate)
     * @param nameString players desired name
     * @param affCode affiliate name of who refered you
     * (this might cost a lot of gas)
     */

    /**
    参数类型：(string memory nameString, string memory affCode) //自己的名字，邀请人的名字
说明：如果邀请人的名字为“”意味着没有邀请者
	每一次注册是需要支付手续费的，【0，99）号用户收取100 finney，【100，199）200 ～
     */
    function registerNameXName(string memory nameString, string memory affCode)
        public
        payable 
    {

        // make sure name fees paid
        require (msg.value >= this.getRegistrationFee(), "umm.....  you have to pay the name fee");

        // filter name + condition checks
        bytes32 name = NameFilter.nameFilter(nameString);
        // if names already has been used
        require(_pIDxName[name] == 0, "sorry that names already taken");

        // set up address 
        address addr = msg.sender;
         // set up our tx event data and determine if player is new or not
        _determinePID(addr);
        // fetch player id
        uint256 pID = _pIDxAddr[addr];
        // if names already has been used
        require(_plyrNames[pID][name] == false, "sorry that names already taken");

        // add name to player profile, registry, and name book
        _plyrNames[pID][name] = true;
        _pIDxName[name] = pID;   
        _plyr[pID].name = name;
        _plyr[pID].nameCount++;

        _totalRegisterCount++;


        //try bind a refer
        if(_plyr[pID].laff == 0){

            bytes memory tempCode = bytes(affCode);
            bytes32 affName = 0x0;
            if (tempCode.length >= 0) {
                assembly {
                    affName := mload(add(tempCode, 32))
                }
            }

            _bindRefer(addr,affName);
        }
        uint256 affID = _plyr[pID].laff;

        // fire event
        emit eveNewName(pID, addr, name, affID, _plyr[affID].addr, _plyr[affID].name, _registrationBaseFee );
    }
    
    /**
     * @dev bind a refer,if affcode invalid, use default refer
     */  
    function bindRefer( address from, string calldata  affCode )
        isRegisteredPool()
        external
        // override
        returns (bool)
    {

        bytes memory tempCode = bytes(affCode);
        bytes32 affName = 0x0;
        if (tempCode.length >= 0) {
            assembly {
                affName := mload(add(tempCode, 32))
            }
        }

        return _bindRefer(from, affName);
    }


    /**
     * @dev bind a refer,if affcode invalid, use default refer
     */  
    function _bindRefer( address from, bytes32  name )
        validAddress(msg.sender)    
        validAddress(from)  
        private
        returns (bool)
    {
        // set up our tx event data and determine if player is new or not
        _determinePID(from);

        // fetch player id
        uint256 pID = _pIDxAddr[from];
        if( _plyr[pID].laff != 0){
            return false;
        }

        if (_pIDxName[name] == 0){
            //unregister name 
            name = _defaulRefer;
        }
      
        uint256 affID = _pIDxName[name];
        if( affID == pID){
            affID = _pIDxName[_defaulRefer];
        }
       
        _plyr[pID].laff = affID;
        //lvcount
        _plyr[affID].lvCount++;
        // fire event
        emit eveBindRefer(pID, from, name, affID, _plyr[affID].addr, _plyr[affID].name);

        return true;
    }
    
    //
    function _determinePID(address addr)
        private
        returns (bool)
    {
        if (_pIDxAddr[addr] == 0)
        {
            _pID++;
            _pIDxAddr[addr] = _pID;
            _plyr[_pID].addr = addr;
            
            // set the new player bool to true
            return (true);
        } else {
            return (false);
        }
    }
    
    function hasRefer(address from) 
        isRegisteredPool()
        external 
        // override
        returns(bool) 
    {
        _determinePID(from);
        uint256 pID =  _pIDxAddr[from];
        return (_plyr[pID].laff > 0);
    }

    //查询某个用户的名字
    function getPlayerName(address from)
        external
        view
        returns (bytes32)
    {
        uint256 pID =  _pIDxAddr[from];
        if(_pID==0){
            return "";
        }
        return (_plyr[pID].name);
    }

    //查询某个用户的邀请者地址
    function getPlayerLaffAddress(address from) external  view returns(address laffAddress) {
        uint256 pID =  _pIDxAddr[from];
        if(_pID==0){
            return _teamWallet;
        }
        uint256 laffID = _plyr[pID].laff;
        if(laffID == 0) {
            return _teamWallet;
        }
        return _plyr[laffID].addr;
    }

    //查询某个用户的邀请者的地址
    function getPlayerLaffName(address from)
        external
        view
        returns (bytes32)
    {
        uint256 pID =  _pIDxAddr[from];
        if(_pID==0){
             return "";
        }

        uint256 aID=_plyr[pID].laff;
        if( aID== 0){
            return "";
        }

        return (_plyr[aID].name);
    }

    //查询某个用户的id，邀请者id，邀请数量
    function getPlayerInfo(address from)
        external
        view
        returns (uint256,uint256,uint256)
    {
        uint256 pID = _pIDxAddr[from];
        if(_pID==0){
             return (0,0,0);
        }
        return (pID,_plyr[pID].laff,_plyr[pID].lvCount);
    }

    //获取当前注册费用
    function getRegistrationFee()
        external
        view
        returns (uint256)
    {
        if( _totalRegisterCount <_registrationStep || _registrationStep == 0){
            return _registrationBaseFee;
        }
        else{
            uint256 step = _totalRegisterCount.div(_registrationStep);
            return _registrationBaseFee.add(step.mul(_stepFee));
        }
    }
}
