// Sources flattened with buidler v1.0.1 https://buidler.dev

// File @openzeppelin/contracts/GSN/Context.sol@v2.4.0

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/ownership/Ownable.sol@v2.4.0

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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


// File @openzeppelin/contracts/math/SafeMath.sol@v2.4.0

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


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v2.4.0

pragma solidity ^0.5.0;

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


// File contracts/IERC20WCC.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20WCC {
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

    function mint(address owner, uint256 amount) external returns (bool);

    function burn(address owner, uint256 amount) external returns (bool);
}


// File contracts/CoffeeHandler.sol

/** @title Coffee Handler
  * @author Affogato
  * @dev Right now only owner can mint and stake
  */
pragma solidity ^0.5.11;





contract CoffeeHandler is Ownable {

  /** @dev Logs all the calls of the functions. */
  event LogSetDAIContract(address indexed _owner, IERC20 _contract);
  event LogSetWCCContract(address indexed _owner, IERC20WCC _contract);
  event LogSetCoffeePrice(address indexed _owner, uint _coffeePrice);
  event LogSetStakeRate(address indexed _owner, uint _stakeRate);
  event LogStakeDAI(address indexed _staker, uint _amount, uint _currentStake);
  event LogRemoveStakedDAI(address indexed _staker, uint _amount, uint _currentStake);
  event LogRemoveAllStakedDAI(address indexed _staker, uint _amount, uint _currentStake);
  event LogMintTokens(address indexed _staker, address owner, uint _amount, uint _currentUsed);
  event LogBurnTokens(address indexed _staker, address owner, uint _amount, uint _currentUsed);
  event LogApproveMint(address indexed _owner, address _staker, uint amount);
  event LogRedeemTokens(address indexed _staker, address owner, uint _amount, uint _currentUsed);
  event LogLiquidateStakedDAI(address indexed _owner, uint _amount);

  using SafeMath for uint256;

  /** @notice address of the WCC Contract used to mint
    * @dev The WCC Contract must have set the coffee handler
    */
  IERC20WCC public WCC_CONTRACT;

  /** @notice address of the DAI Contract used to stake */
  IERC20 public DAI_CONTRACT;

  /** @notice coffee price rounded */
  uint public COFFEE_PRICE;

  /** @notice percentage value with no decimals */
  uint public STAKE_RATE;

  /** @notice mapping of the stake of a validator */
  mapping (address => uint) public userToStake;

  /** @notice mapping of the stake used in a mint */
  mapping (address => uint) public tokensUsed;

  /** @notice mapping of the approval done by an user to a validator */
  mapping (address => mapping (address => uint)) public tokensMintApproved;

  /** @notice mapping of which validator minted a token for a user
    * @dev this is used to see to which validator return the stake
    */
  mapping (address => address) public userToValidator;

  /** @notice date of when the contract was deployed */
  uint256 public openingTime;

  /** @notice Throws if the function called is after 3 months
    * @dev This is temporal for pilot it should be variable depending on coffee
    */
  modifier onlyPaused() {
    /* solium-disable-next-line */
    require(now >= openingTime + 90 days, "only available after 3 months of deployment");
    _;
  }

  /** @notice Throws if the function called is before 3 months
    * @dev This is temporal for pilot it should be variable depending on coffee
    */
  modifier onlyNotPaused() {
    /* solium-disable-next-line */
    require(now <= openingTime + 90 days, "only available during the 3 months of deployment");
    _;
  }

  /** @notice Constructor sets the starting time
    * @dev opening time is only relevant for pilot
    */
  constructor() public {
    /* solium-disable-next-line */
    openingTime = now;
  }

  /** @notice Sets the DAI Contract, Only deployer can change it
    * @param _DAI_CONTRACT address of ERC-20 used as stake
    */
  function setDAIContract(IERC20 _DAI_CONTRACT) public onlyOwner {
    DAI_CONTRACT = _DAI_CONTRACT;
    emit LogSetDAIContract(msg.sender, _DAI_CONTRACT);
  }

  /** @notice Sets the Wrapped Coffee Coin Contract, Only deployer can change it
    * @param _WCC_CONTRACT address of ERC-20 used as stake
    */
  function setWCCContract(IERC20WCC _WCC_CONTRACT) public onlyOwner {
    WCC_CONTRACT = _WCC_CONTRACT;
    emit LogSetWCCContract(msg.sender, _WCC_CONTRACT);
  }

  /** @notice Sets the price of the coffee, Only deployer can change it
    * @param _COFFEE_PRICE uint with the coffee price
    * @dev this function should be called by an oracle after pilot
    */
  function setCoffeePrice(uint _COFFEE_PRICE) public onlyOwner {
    COFFEE_PRICE = _COFFEE_PRICE;
    emit LogSetCoffeePrice(msg.sender, _COFFEE_PRICE);
  }

  /** @notice Sets the stake rate needed for minting tokens, only deployer can change it
    * @param _STAKE_RATE uint with the rate to stake
    */
  function setStakeRate(uint _STAKE_RATE) public onlyOwner{
    STAKE_RATE = _STAKE_RATE;
    emit LogSetStakeRate(msg.sender, _STAKE_RATE);
  }

  /** @notice Allows a user to stake ERC20
    * @param _amount uint with the stake
    * @dev Requires users to approve first in the ERC20
    */
  function stakeDAI(uint _amount) public onlyNotPaused onlyOwner {
    require(DAI_CONTRACT.balanceOf(msg.sender) >= _amount, "Not enough balance");
    require(DAI_CONTRACT.allowance(msg.sender, address(this)) >= _amount, "Contract allowance is to low or not approved");
    userToStake[msg.sender] = userToStake[msg.sender].add(_amount);
    DAI_CONTRACT.transferFrom(msg.sender, address(this), _amount);
    emit LogStakeDAI(msg.sender, _amount, userToStake[msg.sender]);
  }

  /** @notice Allows a user to remove the current available staked ERC20
    * @param _amount uint with the stake to remove
    */
  function _removeStakedDAI(uint _amount) private {
    require(userToStake[msg.sender] >= _amount, "Amount bigger than current available to retrive");
    userToStake[msg.sender] = userToStake[msg.sender].sub(_amount);
    DAI_CONTRACT.transfer(msg.sender, _amount);
  }

  /** @notice Allows a user to remove certain amount of the current available staked ERC20
    * @param _amount uint with the stake to remove
    */
  function removeStakedDAI(uint _amount) public {
    _removeStakedDAI(_amount);
    emit LogRemoveStakedDAI(msg.sender, _amount, userToStake[msg.sender]);
  }

  /** @notice Allows a user to remove all the available staked ERC20 */
  function removeAllStakedDAI() public {
    uint amount = userToStake[msg.sender];
    _removeStakedDAI(amount);
    emit LogRemoveAllStakedDAI(msg.sender, amount, userToStake[msg.sender]);
  }

  /** @notice Allows a validator that has staked ERC20 to mint tokens and assign them to a receiver
    * @param _receiver address of the account that will receive the tokens
    * @param _amount uint with the amount in wei to mint
    * @dev Requires receiver to approve first, it moves the staked ERC20 to another mapping to prove that the stake is being used and unable to retreive.
    */
  function mintTokens(address _receiver, uint _amount) public onlyOwner {
    require(tokensMintApproved[_receiver][msg.sender] >= _amount, "Mint value bigger than approved by user");
    uint expectedAvailable = requiredAmount(_amount);
    require(userToStake[msg.sender] >= expectedAvailable, "Not enough DAI Staked");
    userToStake[msg.sender] = userToStake[msg.sender].sub(expectedAvailable);
    tokensUsed[msg.sender] = tokensUsed[msg.sender].add(_amount);
    tokensMintApproved[_receiver][msg.sender] = 0;
    userToValidator[_receiver] = msg.sender;
    WCC_CONTRACT.mint(_receiver, _amount);
    emit LogMintTokens(msg.sender, _receiver, _amount, tokensUsed[msg.sender]);
  }

  /** @notice Allows an user to burn their tokens and release the used stake for the validator
    * @param _amount uint with the amount in wei to burn
    * @dev This function should be called only when there is a redeem of physical coffee
    */
  function burnTokens(uint _amount) public {
    uint expectedAvailable = requiredAmount(_amount);
    address validator = userToValidator[msg.sender];
    require(tokensUsed[validator] >= _amount, "Burn amount higher than stake minted");
    userToStake[validator] = userToStake[validator].add(expectedAvailable);
    tokensUsed[validator] = tokensUsed[validator].sub(_amount);
    WCC_CONTRACT.burn(msg.sender, _amount);
    emit LogBurnTokens(validator, msg.sender, _amount, tokensUsed[validator]);
  }

  /** @notice Calculate the amount of stake needed to mint an amount of tokens.
    * @param _amount uint with the amount in wei
    * @return the amount of stake needed
    * @dev (AMOUNT X COFFEE_PRICE X STAKE RATE) / 100
    */
  function requiredAmount(uint _amount) public view returns(uint) {
    return _amount.mul(COFFEE_PRICE.mul(STAKE_RATE)).div(100);
  }

  /** @notice Approves a validator to mint certain amount of tokens and receive them
    * @param _validator address of the validator
    * @param _amount uint with the amount in wei
    */
  function approveMint(address _validator, uint _amount) public {
    tokensMintApproved[msg.sender][_validator] = _amount;
    emit LogApproveMint(msg.sender, _validator, _amount);
  }

  /** @notice Allows token holders to change their tokens for DAI after 3 months
    * @param _amount uint with the amount in wei to redeem
    */
  function redeemTokens(uint _amount) public onlyPaused {
    uint expectedAvailable = requiredAmount(_amount);
    address validator = userToValidator[msg.sender];
    require(tokensUsed[validator] >= _amount, "Redeem amount is higher than redeemable amount");
    uint tokenToDai = COFFEE_PRICE.mul(_amount);
    userToStake[validator] = userToStake[validator].add(expectedAvailable).sub(tokenToDai);
    tokensUsed[validator] = tokensUsed[validator].sub(_amount);
    WCC_CONTRACT.burn(msg.sender, _amount);
    DAI_CONTRACT.transfer(msg.sender, tokenToDai);
    emit LogRedeemTokens(validator, msg.sender, _amount, tokensUsed[validator]);
  }

  /** @notice After 6 months it allows the deployer to retrieve all DAI locked in contract.
    * @dev safeguard for when the pilot ends
    */
  function liquidateStakedDAI() public onlyOwner {
    /* solium-disable-next-line */
    require(now >= openingTime + 90 days, "only available after 6 months of deployment");
    uint amount = DAI_CONTRACT.balanceOf(address(this));
    DAI_CONTRACT.transfer(owner(), amount);
    emit LogLiquidateStakedDAI(msg.sender, amount);
  }
}


// File @openzeppelin/contracts/token/ERC20/ERC20.sol@v2.4.0

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}


// File @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol@v2.4.0

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
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
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


// File @openzeppelin/contracts/access/Roles.sol@v2.4.0

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


// File @openzeppelin/contracts/access/roles/MinterRole.sol@v2.4.0

pragma solidity ^0.5.0;



contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}


// File @openzeppelin/contracts/token/ERC20/ERC20Mintable.sol@v2.4.0

pragma solidity ^0.5.0;



/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}


// File contracts/DaiToken.sol

/** @dev This contract is for testing only */
pragma solidity ^0.5.11;





contract DaiToken is ERC20Detailed, ERC20Mintable, Ownable {
  constructor() ERC20Detailed("Dai Stablecoin v1.0 TEST", "DAI", 18) public {}

  function faucet(uint amount) public{
    _mint(msg.sender, amount);
  }
}


// File contracts/WrappedCoffeeCoin.sol

/** @title Wrapped Coffee Coin
  * @author Affogato
  * @notice An ERC that will represent deposited coffee to a validator having DAI staked as collateral.
  * @dev When deploying the contract the deployer needs to specify the coffee handler and renounce as minter.
  * @dev this is a pilot contract
  */
pragma solidity ^0.5.11;





contract WrappedCoffeeCoin is ERC20, ERC20Detailed, Ownable, MinterRole {

  /** @dev Logs all the calls of the functions. */
  event LogSetCoffeeHandler(address indexed _owner, address _contract);
  event LogUpdateCoffee(address indexed _owner, string _ipfsHash);

  /** @notice an ipfs hash of the json with the coffee information */
  string private ipfsHash;
  /** @notice address of the coffee handler contract */
  address public coffeeHandler;

  /** @notice Initializes the ERC20 Details*/
  constructor() ERC20Detailed("Single Coffee Token", "CAFE", 18) public {}

  /** @notice Sets the coffee handler
    * @param _coffeeHandler address of the coffee handler contract allowed to mint tokens
    * @dev owner renounces as minter, it's not done in constructor due to a bug
    */
  function setCoffeeHandler(address _coffeeHandler) public onlyOwner{
    addMinter(_coffeeHandler);
    coffeeHandler = _coffeeHandler;
    renounceMinter();
    emit LogSetCoffeeHandler(msg.sender, _coffeeHandler);
  }

  /** @notice Called when a minter wants to create new tokens
    * @param _account account to be assigned the minted tokens
    * @param _amount amount of tokens to be minted
    * @dev See `ERC20._mint`, coffee handler address must be set before minting
    */
  function mint(address _account, uint256 _amount) public onlyMinter returns (bool) {
    require(coffeeHandler != address(0), "Coffee Handler must be set");
    _mint(_account, _amount);
    return true;
  }

  /** @notice Called when a minter wants to burn the tokens
    * @param _account account to be assigned the burned tokens
    * @param _amount amount of tokens to be burned
    * @dev See `ERC20._mint`.  coffee handler address must be set before minting
    */
  function burn(address _account, uint256 _amount) public onlyMinter returns (bool) {
    require(coffeeHandler != address(0), "Coffee Handler must be set");
    _burn(_account, _amount);
    return true;
  }

  /** @notice Returns the hash pointer to the file containing the details about the coffee this token represents.
    * @return string with the ipsh hash pointing to a json with the coffee information
    */
  function getCoffee() public view returns(string memory) {
    return ipfsHash;
  }

  /** @notice Updates the IPFS pointer for the information about this coffee.
    * @param _ipfs ipfs hash
    */
  function updateCoffee(string memory _ipfs) public onlyOwner {
    require(bytes(_ipfs).length != 0, "The IPFS pointer cannot be empty");
    ipfsHash = _ipfs;
    emit LogUpdateCoffee(msg.sender, ipfsHash);
  }
}
