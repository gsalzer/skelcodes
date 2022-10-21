
// File: browser/TokenUpgrader.sol

pragma solidity ^0.5.0;


/**
 * Token upgrader interface inspired by Lunyr.
 *
 * Token upgrader transfers previous version tokens to a newer version.
 * Token upgrader itself can be the token contract, or just a middle man contract doing the heavy lifting.
 */
contract TokenUpgrader {
    uint public originalSupply;

    /** Interface marker */
    function isTokenUpgrader() external pure returns (bool) {
        return true;
    }

    function upgradeFrom(address _from, uint256 _value) public;
}

// File: github.com/OpenZeppelin/zeppelin-solidity/contracts/GSN/Context.sol

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

// File: github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// File: github.com/OpenZeppelin/zeppelin-solidity/contracts/access/Roles.sol

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

// File: browser/AgentRole.sol

pragma solidity ^0.5.0;



contract AgentRole is Ownable {
    using Roles for Roles.Role;

    event AgentAdded(address indexed account);
    event AgentRemoved(address indexed account);

    Roles.Role private _agents;

    modifier onlyAgent() {
        require(isAgent(msg.sender), "AgentRole: caller does not have the Agent role");
        _;
    }

    function isAgent(address account) public view returns (bool) {
        return _agents.has(account);
    }

    function addAgent(address account) public onlyOwner {
        _addAgent(account);
    }

    function removeAgent(address account) public onlyOwner {
        _removeAgent(account);
    }

    function _addAgent(address account) internal {
        _agents.add(account);
        emit AgentAdded(account);
    }

    function _removeAgent(address account) internal {
        _agents.remove(account);
        emit AgentRemoved(account);
    }
}

// File: github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: browser/ICompliance.sol

pragma solidity ^0.5.10;

interface ICompliance {
    function canTransfer(address _from, address _to, uint256 value) external returns (bool);
}

// File: browser/IClaimIssuer.sol

pragma solidity ^0.5.10;


//interface
contract IClaimIssuer{
    uint public issuedClaimCount;

    mapping (bytes => bool) revokedClaims;
    mapping (bytes32 => address) identityAddresses;

    event ClaimValid(Identity _identity, uint256 claimTopic);
    event ClaimInvalid(Identity _identity, uint256 claimTopic);

    function revokeClaim(bytes32 _claimId, address _identity) public returns(bool);
    // function revokeClaim(bytes memory _sig, address _identity) public returns(bool);
    // function isClaimRevoked(bytes32 _claimId) public view returns(bool);
    function isClaimRevoked(bytes memory _sig) public view returns(bool result);
    function isClaimValid(Identity _identity, bytes32 _claimId, uint256 claimTopic, bytes memory sig, bytes memory data)
    public
    view
    returns (bool claimValid);

}

// File: browser/ITrustedIssuersRegistry.sol

pragma solidity ^0.5.10;


interface ITrustedIssuersRegistry {
    // EVENTS
    event TrustedIssuerAdded(uint indexed index, ClaimIssuer indexed trustedIssuer, uint[] claimTopics);
    event TrustedIssuerRemoved(uint indexed index, ClaimIssuer indexed trustedIssuer);
    event TrustedIssuerUpdated(uint indexed index, ClaimIssuer indexed oldTrustedIssuer, ClaimIssuer indexed newTrustedIssuer, uint[] claimTopics);

    // READ OPERATIONS
    function getTrustedIssuer(uint index) external view returns (ClaimIssuer);
    function getTrustedIssuerClaimTopics(uint index) external view returns(uint[] memory);
    function getTrustedIssuers() external view returns (uint[] memory);
    function hasClaimTopic(address issuer, uint claimTopic) external view returns(bool);
    function isTrustedIssuer(address issuer) external view returns(bool);

    // WRITE OPERATIONS
    function addTrustedIssuer(ClaimIssuer _trustedIssuer, uint index, uint[] calldata claimTopics) external;
    function removeTrustedIssuer(uint index) external;
    function updateIssuerContract(uint index, ClaimIssuer _newTrustedIssuer, uint[] calldata claimTopics) external;
}

// File: browser/IIdentityRegistry.sol

pragma solidity ^0.5.10;





interface IIdentityRegistry {
    // EVENTS
    event ClaimTopicsRegistrySet(address indexed _claimTopicsRegistry);
    event CountryUpdated(address indexed investorAddress, uint16 indexed country);
    event IdentityRegistered(address indexed investorAddress, Identity indexed identity);
    event IdentityRemoved(address indexed investorAddress, Identity indexed identity);
    event IdentityUpdated(Identity indexed old_identity, Identity indexed new_identity);
    event TrustedIssuersRegistrySet(address indexed _trustedIssuersRegistry);

    // WRITE OPERATIONS
    function deleteIdentity(address _user) external;
    function registerIdentity(address _user, Identity _identity, uint16 _country) external;
    function setClaimTopicsRegistry(address _claimTopicsRegistry) external;
    function setTrustedIssuersRegistry(address _trustedIssuersRegistry) external;
    function updateCountry(address _user, uint16 _country) external;
    function updateIdentity(address _user, Identity _identity) external;

    // READ OPERATIONS
    function contains(address _wallet) external view returns (bool);
    function isVerified(address _userAddress) external view returns (bool);

    // GETTERS
    function identity(address _wallet) external view returns (Identity);
    function investorCountry(address _wallet) external view returns (uint16);
    function issuersRegistry() external view returns (ITrustedIssuersRegistry);
    function topicsRegistry() external view returns (IClaimTopicsRegistry);
}

// File: browser/IClaimTopicsRegistry.sol

pragma solidity ^0.5.10;

interface IClaimTopicsRegistry{
    // EVENTS
    event ClaimTopicAdded(uint256 indexed claimTopic);
    event ClaimTopicRemoved(uint256 indexed claimTopic);

    // OPERATIONS
    function addClaimTopic(uint256 claimTopic) external;
    function removeClaimTopic(uint256 claimTopic) external;

    // GETTERS
    function getClaimTopics() external view returns (uint256[] memory);
}

// File: browser/IERC735.sol

pragma solidity ^0.5.10;

/**
 * @dev Interface of the ERC735 (Claim Holder) standard as defined in the EIP.
 */
interface IERC735 {

    /**
     * @dev Emitted when a claim request was performed.
     *
     * Specification: Is not clear
     */
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was added.
     *
     * Specification: MUST be triggered when a claim was successfully added.
     */
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was removed.
     *
     * Specification: MUST be triggered when removeClaim was successfully called.
     */
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was changed.
     *
     * Specification: MUST be triggered when changeClaim was successfully called.
     */
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Definition of the structure of a Claim.
     *
     * Specification: Claims are information an issuer has about the identity holder.
     * The structure should be as follows:
     *   - claim: A claim published for the Identity.
     *      - topic: A uint256 number which represents the topic of the claim. (e.g. 1 biometric, 2 residence (ToBeDefined: number schemes, sub topics based on number ranges??))
     *      - scheme : The scheme with which this claim SHOULD be verified or how it should be processed. Its a uint256 for different schemes. E.g. could 3 mean contract verification, where the data will be call data, and the issuer a contract address to call (ToBeDefined). Those can also mean different key types e.g. 1 = ECDSA, 2 = RSA, etc. (ToBeDefined)
     *      - issuer: The issuers identity contract address, or the address used to sign the above signature. If an identity contract, it should hold the key with which the above message was signed, if the key is not present anymore, the claim SHOULD be treated as invalid. The issuer can also be a contract address itself, at which the claim can be verified using the call data.
     *      - signature: Signature which is the proof that the claim issuer issued a claim of topic for this identity. it MUST be a signed message of the following structure: `keccak256(abi.encode(identityHolder_address, topic, data))`
     *      - data: The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
     *      - uri: The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
     */
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

    /**
     * @dev Get a claim by its ID.
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function getClaim(bytes32 _claimId) external view returns(uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);

    /**
     * @dev Returns an array of claim IDs by topic.
     */
    function getClaimIdsByTopic(uint256 _topic) external view returns(bytes32[] memory claimIds);

    /**
     * @dev Add or update a claim.
     *
     * Triggers Event: `ClaimRequested`, `ClaimAdded`, `ClaimChanged`
     *
     * Specification: Requests the ADDITION or the CHANGE of a claim from an issuer.
     * Claims can requested to be added by anybody, including the claim holder itself (self issued).
     *
     * _signature is a signed message of the following structure: `keccak256(abi.encode(address identityHolder_address, uint256 topic, bytes data))`.
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address + uint256 topic))`.
     *
     * This COULD implement an approval process for pending claims, or add them right away.
     * MUST return a claimRequestId (use claim ID) that COULD be sent to the approve function.
     */
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, bytes calldata _signature, bytes calldata _data, string calldata _uri) external returns (bytes32 claimRequestId);

    /**
     * @dev Removes a claim.
     *
     * Triggers Event: `ClaimRemoved`
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function removeClaim(bytes32 _claimId) external returns (bool success);
}

// File: browser/IERC734.sol

pragma solidity ^0.5.10;

/**
 * @dev Interface of the ERC734 (Key Holder) standard as defined in the EIP.
 */
interface IERC734 {
    /**
     * @dev Definition of the structure of a Key.
     *
     * Specification: Keys are cryptographic public keys, or contract addresses associated with this identity.
     * The structure should be as follows:
     *   - key: A public key owned by this identity
     *      - purposes: uint256[] Array of the key purposes, like 1 = MANAGEMENT, 2 = EXECUTION
     *      - keyType: The type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
     *      - key: bytes32 The public key. // Its the Keccak256 hash of the key
     */
    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }

    /**
     * @dev Emitted when an execution request was approved.
     *
     * Specification: MUST be triggered when approve was successfully called.
     */
    event Approved(uint256 indexed executionId, bool approved);

    /**
     * @dev Emitted when an execute operation was approved and successfully performed.
     *
     * Specification: MUST be triggered when approve was called and the execution was successfully approved.
     */
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when an execution request was performed via `execute`.
     *
     * Specification: MUST be triggered when execute was successfully called.
     */
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when a key was added to the Identity.
     *
     * Specification: MUST be triggered when addKey was successfully called.
     */
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when a key was removed from the Identity.
     *
     * Specification: MUST be triggered when removeKey was successfully called.
     */
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when the list of required keys to perform an action was updated.
     *
     * Specification: MUST be triggered when changeKeysRequired was successfully called.
     */
    event KeysRequiredChanged(uint256 purpose, uint256 number);


    /**
     * @dev Adds a _key to the identity. The _purpose specifies the purpose of the key.
     *
     * Triggers Event: `KeyAdded`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) external returns (bool success);

    /**
    * @dev Approves an execution or claim addition.
    *
    * Triggers Event: `Approved`, `Executed`
    *
    * Specification:
    * This SHOULD require n of m approvals of keys purpose 1, if the _to of the execution is the identity contract itself, to successfully approve an execution.
    * And COULD require n of m approvals of keys purpose 2, if the _to of the execution is another contract, to successfully approve an execution.
    */
    function approve(uint256 _id, bool _approve) external returns (bool success);

    /**
     * @dev Changes the keys required to perform an action for a specific purpose. (This is the n in an n of m multisig approval process.)
     *
     * Triggers Event: `KeysRequiredChanged`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function changeKeysRequired(uint256 purpose, uint256 number) external;

    /**
     * @dev Passes an execution instruction to an ERC725 identity.
     *
     * Triggers Event: `ExecutionRequested`, `Executed`
     *
     * Specification:
     * SHOULD require approve to be called with one or more keys of purpose 1 or 2 to approve this execution.
     * Execute COULD be used as the only accessor for `addKey` and `removeKey`.
     */
    function execute(address _to, uint256 _value, bytes calldata _data) external payable returns (uint256 executionId);

    /**
     * @dev Returns the full key data, if present in the identity.
     */
    function getKey(bytes32 _key) external view returns (uint256[] memory purposes, uint256 keyType, bytes32 key);

    /**
     * @dev Returns the list of purposes associated with a key.
     */
    function getKeyPurposes(bytes32 _key) external view returns(uint256[] memory _purposes);

    /**
     * @dev Returns an array of public key bytes32 held by this identity.
     */
    function getKeysByPurpose(uint256 _purpose) external view returns (bytes32[] memory keys);

    /**
     * @dev Returns number of keys required for purpose.
     */
    function getKeysRequired(uint256 purpose) external view returns (uint256);

    /**
     * @dev Returns TRUE if a key is present and has the given purpose. If the key is not present it returns FALSE.
     */
    function keyHasPurpose(bytes32 _key, uint256 _purpose) external view returns (bool exists);

    /**
     * @dev Removes _purpose for _key from the identity.
     *
     * Triggers Event: `KeyRemoved`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function removeKey(bytes32 _key, uint256 _purpose) external returns (bool success);
}

// File: browser/ERC734.sol

pragma solidity ^0.5.10;


/**
 * @dev Implementation of the `IERC734` "KeyHolder" interface.
 */
contract ERC734 is IERC734 {
    uint256 public constant MANAGEMENT_KEY = 1;
    uint256 public constant ACTION_KEY = 2;
    uint256 public constant CLAIM_SIGNER_KEY = 3;
    uint256 public constant ENCRYPTION_KEY = 4;

    uint256 private executionNonce;

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

    mapping (bytes32 => Key) private keys;
    mapping (uint256 => bytes32[]) private keysByPurpose;
    mapping (uint256 => Execution) private executions;

    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    constructor() public {
        bytes32 _key = keccak256(abi.encode(msg.sender));

        keys[_key].key = _key;
        keys[_key].purposes = [1];
        keys[_key].keyType = 1;

        keysByPurpose[1].push(_key);

        emit KeyAdded(_key, 1, 1);
    }

    /**
       * @notice Implementation of the getKey function from the ERC-734 standard
       *
       * @param _key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
       *
       * @return Returns the full key data, if present in the identity.
       */
    function getKey(bytes32 _key)
    public
    view
    returns(uint256[] memory purposes, uint256 keyType, bytes32 key)
    {
        return (keys[_key].purposes, keys[_key].keyType, keys[_key].key);
    }

    /**
    * @notice gets the purposes of a key
    *
    * @param _key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
    *
    * @return Returns the purposes of the specified key
    */
    function getKeyPurposes(bytes32 _key)
    public
    view
    returns(uint256[] memory _purposes)
    {
        return (keys[_key].purposes);
    }

    /**
        * @notice gets all the keys with a specific purpose from an identity
        *
        * @param _purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
        *
        * @return Returns an array of public key bytes32 hold by this identity and having the specified purpose
        */
    function getKeysByPurpose(uint256 _purpose)
    public
    view
    returns(bytes32[] memory _keys)
    {
        return keysByPurpose[_purpose];
    }

    /**
        * @notice implementation of the addKey function of the ERC-734 standard
        * Adds a _key to the identity. The _purpose specifies the purpose of key. Initially we propose four purposes:
        * 1: MANAGEMENT keys, which can manage the identity
        * 2: ACTION keys, which perform actions in this identities name (signing, logins, transactions, etc.)
        * 3: CLAIM signer keys, used to sign claims on other identities which need to be revokable.
        * 4: ENCRYPTION keys, used to encrypt data e.g. hold in claims.
        * MUST only be done by keys of purpose 1, or the identity itself.
        * If its the identity itself, the approval process will determine its approval.
        *
        * @param _key keccak256 representation of an ethereum address
        * @param _type type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
        * @param _purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
        *
        * @return Returns TRUE if the addition was successful and FALSE if not
        */

    function addKey(bytes32 _key, uint256 _purpose, uint256 _type)
    public
    returns (bool success)
    {
        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Permissions: Sender does not have management key");
        }

        if (keys[_key].key == _key) {
            for (uint keyPurposeIndex = 0; keyPurposeIndex < keys[_key].purposes.length; keyPurposeIndex++) {
                uint256 purpose = keys[_key].purposes[keyPurposeIndex];

                if (purpose == _purpose) {
                    revert("Conflict: Key already has purpose");
                }
            }

            keys[_key].purposes.push(_purpose);
        } else {
            keys[_key].key = _key;
            keys[_key].purposes = [_purpose];
            keys[_key].keyType = _type;
        }

        keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _type);

        return true;
    }

    function approve(uint256 _id, bool _approve)
    public
    returns (bool success)
    {
        require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), "Sender does not have action key");

        emit Approved(_id, _approve);

        if (_approve == true) {
            executions[_id].approved = true;

            (success,) = executions[_id].to.call.value(executions[_id].value)(abi.encode(executions[_id].data, 0));

            if (success) {
                executions[_id].executed = true;

                emit Executed(
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );

                return true;
            } else {
                emit ExecutionFailed(
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );

                return false;
            }
        } else {
            executions[_id].approved = false;
        }
        return true;
    }

    function execute(address _to, uint256 _value, bytes memory _data)
    public
    payable
    returns (uint256 executionId)
    {
        require(!executions[executionNonce].executed, "Already executed");
        executions[executionNonce].to = _to;
        executions[executionNonce].value = _value;
        executions[executionNonce].data = _data;

        emit ExecutionRequested(executionNonce, _to, _value, _data);

        if (keyHasPurpose(keccak256(abi.encode(msg.sender)), 2)) {
            approve(executionNonce, true);
        }

        executionNonce++;
        return executionNonce-1;
    }

    function removeKey(bytes32 _key, uint256 _purpose)
    public
    returns (bool success)
    {
        require(keys[_key].key == _key, "NonExisting: Key isn't registered");

        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Permissions: Sender does not have management key"); // Sender has MANAGEMENT_KEY
        }

        require(keys[_key].purposes.length > 0, "NonExisting: Key doesn't have such purpose");

        uint purposeIndex = 0;
        while (keys[_key].purposes[purposeIndex] != _purpose) {
            purposeIndex++;

            if (purposeIndex >= keys[_key].purposes.length) {
                break;
            }
        }

        require(purposeIndex < keys[_key].purposes.length, "NonExisting: Key doesn't have such purpose");

        keys[_key].purposes[purposeIndex] = keys[_key].purposes[keys[_key].purposes.length - 1];
        keys[_key].purposes.pop();

        uint keyIndex = 0;

        while (keysByPurpose[_purpose][keyIndex] != _key) {
            keyIndex++;
        }

        keysByPurpose[_purpose][keyIndex] = keysByPurpose[_purpose][keysByPurpose[_purpose].length - 1];
        keysByPurpose[_purpose].pop();

        uint keyType = keys[_key].keyType;

        if (keys[_key].purposes.length == 0) {
            delete keys[_key];
        }

        emit KeyRemoved(_key, _purpose, keyType);

        return true;
    }

    /**
    * @notice implementation of the changeKeysRequired from ERC-734 standard
    */
    function changeKeysRequired(uint256 purpose, uint256 number) external
    {
        revert();
    }

    /**
    * @notice implementation of the getKeysRequired from ERC-734 standard
    */
    function getKeysRequired(uint256 purpose) external view returns(uint256 number)
    {
        revert();
    }

    /**
    * @notice Returns true if the key has MANAGEMENT purpose or the specified purpose.
    */
    function keyHasPurpose(bytes32 _key, uint256 _purpose)
    public
    view
    returns(bool result)
    {
        Key memory key = keys[_key];
        if (key.key == 0) return false;

        for (uint keyPurposeIndex = 0; keyPurposeIndex < key.purposes.length; keyPurposeIndex++) {
            uint256 purpose = key.purposes[keyPurposeIndex];

            if (purpose == MANAGEMENT_KEY || purpose == _purpose) return true;
        }

        return false;
    }
}

// File: browser/Identity.sol

pragma solidity ^0.5.10;



/**
 * @dev Implementation of the `IERC734` "KeyHolder" and the `IERC735` "ClaimHolder" interfaces into a common Identity Contract.
 */
contract Identity is ERC734, IERC735 {

    mapping (bytes32 => Claim) private claims;
    mapping (uint256 => bytes32[]) private claimsByTopic;

    /**
       * @notice Implementation of the addClaim function from the ERC-735 standard
       *  Require that the msg.sender has claim signer key.
       *
       * @param _topic The type of claim
       * @param _scheme The scheme with which this claim SHOULD be verified or how it should be processed.
       * @param _issuer The issuers identity contract address, or the address used to sign the above signature.
       * @param _signature Signature which is the proof that the claim issuer issued a claim of topic for this identity.
       * it MUST be a signed message of the following structure: keccak256(abi.encode(address identityHolder_address, uint256 _ topic, bytes data))
       * @param _data The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
       * @param _uri The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
       *
       * @return Returns claimRequestId: COULD be send to the approve function, to approve or reject this claim.
       * triggers ClaimAdded event.
       */

    function addClaim(
        uint256 _topic,
        uint256 _scheme,
        address _issuer,
        bytes memory _signature,
        bytes memory _data,
        string memory _uri
    )
    public
    returns (bytes32 claimRequestId)
    {
        bytes32 claimId = keccak256(abi.encode(_issuer, _topic));

        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 3), "Permissions: Sender does not have claim signer key");
        }

        if (claims[claimId].issuer != _issuer) {
            claimsByTopic[_topic].push(claimId);
            claims[claimId].topic = _topic;
            claims[claimId].scheme = _scheme;
            claims[claimId].issuer = _issuer;
            claims[claimId].signature = _signature;
            claims[claimId].data = _data;
            claims[claimId].uri = _uri;

            emit ClaimAdded(
                claimId,
                _topic,
                _scheme,
                _issuer,
                _signature,
                _data,
                _uri
            );
        } else {
            claims[claimId].topic = _topic;
            claims[claimId].scheme = _scheme;
            claims[claimId].issuer = _issuer;
            claims[claimId].signature = _signature;
            claims[claimId].data = _data;
            claims[claimId].uri = _uri;

            emit ClaimChanged(
                claimId,
                _topic,
                _scheme,
                _issuer,
                _signature,
                _data,
                _uri
            );
        }

        return claimId;
    }

    /**
       * @notice Implementation of the removeClaim function from the ERC-735 standard
       * Require that the msg.sender has management key.
       * Can only be removed by the claim issuer, or the claim holder itself.
       *
       * @param _claimId The identity of the claim i.e. keccak256(abi.encode(_issuer, _topic))
       *
       * @return Returns TRUE when the claim was removed.
       * triggers ClaimRemoved event
       */

    function removeClaim(bytes32 _claimId) public returns (bool success) {
        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Permissions: Sender does not have CLAIM key");
        }

        if (claims[_claimId].topic == 0) {
            revert("NonExisting: There is no claim with this ID");
        }

        uint claimIndex = 0;
        while (claimsByTopic[claims[_claimId].topic][claimIndex] != _claimId) {
            claimIndex++;
        }

        claimsByTopic[claims[_claimId].topic][claimIndex] = claimsByTopic[claims[_claimId].topic][claimsByTopic[claims[_claimId].topic].length - 1];
        claimsByTopic[claims[_claimId].topic].pop();

        emit ClaimRemoved(
            _claimId,
            claims[_claimId].topic,
            claims[_claimId].scheme,
            claims[_claimId].issuer,
            claims[_claimId].signature,
            claims[_claimId].data,
            claims[_claimId].uri
        );

        delete claims[_claimId];

        return true;
    }

    /**
        * @notice Implementation of the getClaim function from the ERC-735 standard.
        *
        * @param _claimId The identity of the claim i.e. keccak256(abi.encode(_issuer, _topic))
        *
        * @return Returns all the parameters of the claim for the specified _claimId (topic, scheme, signature, issuer, data, uri) .
        */

    function getClaim(bytes32 _claimId)
    public
    view
    returns(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    )
    {
        return (
            claims[_claimId].topic,
            claims[_claimId].scheme,
            claims[_claimId].issuer,
            claims[_claimId].signature,
            claims[_claimId].data,
            claims[_claimId].uri
        );
    }

    /**
        * @notice Implementation of the getClaimIdsByTopic function from the ERC-735 standard.
        * used to get all the claims from the specified topic
        *
        * @param _topic The identity of the claim i.e. keccak256(abi.encode(_issuer, _topic))
        *
        * @return Returns an array of claim IDs by topic.
        */

    function getClaimIdsByTopic(uint256 _topic)
    public
    view
    returns(bytes32[] memory claimIds)
    {
        return claimsByTopic[_topic];
    }
}

// File: browser/ClaimIssuer.sol

pragma solidity ^0.5.10;



contract ClaimIssuer is IClaimIssuer, Identity {
    function revokeClaim(bytes32 _claimId, address _identity) public returns(bool) {
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory  sig;
        bytes  memory data;

		if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Permissions: Sender does not have management key");
        }
		
        ( foundClaimTopic, scheme, issuer, sig, data, ) = Identity(_identity).getClaim(_claimId);
        // require(sig != 0, "Claim does not exist");

        revokedClaims[sig] = true;
        identityAddresses[_claimId] = _identity;
        return true;
    }

    function isClaimRevoked(bytes memory _sig) public view returns (bool) {
        if(revokedClaims[_sig]) {
            return true;
        }

        return false;
    }

    function isClaimValid(Identity _identity, bytes32 _claimId, uint256 claimTopic, bytes memory sig, bytes memory data)
    public
    view
    returns (bool claimValid)
    {
        bytes32 dataHash = keccak256(abi.encode(_identity, claimTopic, data));
        // Use abi.encodePacked to concatenate the messahe prefix and the message to sign.
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));

        // Recover address of data signer
        address recovered = getRecoveredAddress(sig, prefixedHash);

        // Take hash of recovered address
        bytes32 hashedAddr = keccak256(abi.encode(recovered));

        // Does the trusted identifier have they key which signed the user's claim?
        //  && (isClaimRevoked(_claimId) == false)
        if (keyHasPurpose(hashedAddr, 3) && (isClaimRevoked(sig) == false)) {
            return true;
        }

        return false;
    }

    function getRecoveredAddress(bytes memory sig, bytes32 dataHash)
        public
        pure
        returns (address addr)
    {
        bytes32 ra;
        bytes32 sa;
        uint8 va;

        // Check the signature length
        if (sig.length != 65) {
            return address(0);
        }

        // Divide the signature in r, s and v variables
        assembly {
          ra := mload(add(sig, 32))
          sa := mload(add(sig, 64))
          va := byte(0, mload(add(sig, 96)))
        }

        if (va < 27) {
            va += 27;
        }

        address recoveredAddress = ecrecover(dataHash, va, ra, sa);

        return (recoveredAddress);
    }
}

// File: browser/TransferManager.sol

pragma solidity ^0.5.10;




// import "openzeppelin-solidity/contracts/ownership/Ownable.sol";





contract Pausable is AgentRole, ERC20 {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyAgent whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyAgent whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


contract TransferManager is Pausable {

    mapping(address => uint256) private holderIndices;
    mapping(address => address) private cancellations;
    mapping (address => bool) frozen;
    mapping (address => Identity)  _identity;
    mapping (address => uint256) public freezedTokens;

    mapping(uint16 => uint256) countryShareHolders;
	
    address[] private shareholders;
    bytes32[] public claimsNotInNewAddress;

    IIdentityRegistry public identityRegistry;

    ICompliance public compliance;

    event IdentityRegistryAdded(address indexed _identityRegistry);

    event ComplianceAdded(address indexed _compliance);

    event VerifiedAddressSuperseded(
        address indexed original,
        address indexed replacement,
        address indexed sender
    );

    event AddressFrozen(
        address indexed addr,
        bool indexed isFrozen,
        address indexed owner
    );

    event recoverySuccess(
        address wallet_lostAddress,
        address wallet_newAddress,
        address onchainID
    );

    event recoveryFails(
        address wallet_lostAddress,
        address wallet_newAddress,
        address onchainID
    );

    event TokensFreezed(address indexed addr, uint256 amount);
    
    event TokensUnfreezed(address indexed addr, uint256 amount);
    
    constructor (
        address _identityRegistry,
        address _compliance
    ) public {
        identityRegistry = IIdentityRegistry(_identityRegistry);
        emit IdentityRegistryAdded(_identityRegistry);
        compliance = ICompliance(_compliance);
        emit ComplianceAdded(_compliance);
    }

    /**
    * @notice ERC-20 overridden function that include logic to check for trade validity.
    *  Require that the msg.sender and to addresses are not frozen.
    *  Require that the value should not exceed available balance .
    *  Require that the to address is a verified address,
    *  If the `to` address is not currently a shareholder then it MUST become one.
    *  If the transfer will reduce `msg.sender`'s balance to 0 then that address
    *  MUST be removed from the list of shareholders.
    *
    * @param _to The address of the receiver
    * @param _value The number of tokens to transfer
    *
    * @return `true` if successful and revert if unsuccessful
    */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozen[_to] && !frozen[msg.sender]);
        require(_value <=  balanceOf(msg.sender).sub(freezedTokens[msg.sender]), "Insufficient Balance" );
        if(identityRegistry.isVerified(_to) && compliance.canTransfer(msg.sender, _to, _value)){
            updateShareholders(_to);
            pruneShareholders(msg.sender, _value);
            return super.transfer(_to, _value);
        }

        revert("Transfer not possible");
    }

    /**
    * @notice ERC-20 overridden function that include logic to check for trade validity.
    *  Require that the from and to addresses are not frozen.
    *  Require that the value should not exceed available balance .
    *  Require that the to address is a verified address,
    *  If the `to` address is not currently a shareholder then it MUST become one.
    *  If the transfer will reduce `from`'s balance to 0 then that address
    *  MUST be removed from the list of shareholders.
    *
    * @param _from The address of the sender
    * @param _to The address of the receiver
    * @param _value The number of tokens to transfer
    *
    * @return `true` if successful and revert if unsuccessful
    */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozen[_to] && !frozen[_from]);
        require(_value <=  balanceOf(_from).sub(freezedTokens[_from]), "Insufficient Balance" );
        if(identityRegistry.isVerified(_to) && compliance.canTransfer(_from, _to, _value)){
            updateShareholders(_to);
            pruneShareholders(_from, _value);
            return super.transferFrom(_from, _to, _value);
        }

        revert("Transfer not possible");
    }

    /**
     * Holder count simply returns the total number of token holder addresses.
     */
    function holderCount()
        public
        view
        returns (uint)
    {
        return shareholders.length;
    }

    /**
     *  By counting the number of token holders using `holderCount`
     *  you can retrieve the complete list of token holders, one at a time.
     *  It MUST throw if `index >= holderCount()`.
     *  @param index The zero-based index of the holder.
     *  @return the address of the token holder with the given index.
     */
    function holderAt(uint256 index)
        public
        onlyOwner
        view
        returns (address)
    {
        require(index < shareholders.length);
        return shareholders[index];
    }


    /**
     *  If the address is not in the `shareholders` array then push it
     *  and update the `holderIndices` mapping.
     *  @param addr The address to add as a shareholder if it's not already.
     */
    function updateShareholders(address addr)
        internal
    {
        if (holderIndices[addr] == 0) {
            holderIndices[addr] = shareholders.push(addr);
            uint16 country = identityRegistry.investorCountry(addr);
            countryShareHolders[country]++;
        }
    }

    /**
     *  If the address is in the `shareholders` array and the forthcoming
     *  transfer or transferFrom will reduce their balance to 0, then
     *  we need to remove them from the shareholders array.
     *  @param addr The address to prune if their balance will be reduced to 0.
     @  @dev see https://ethereum.stackexchange.com/a/39311
     */
    function pruneShareholders(address addr, uint256 value)
        internal
    {
        uint256 balance = balanceOf(addr) - value;
        // uint256 balance = balanceOf(addr)
        if (balance > 0) {
            return;
        }
        uint256 holderIndex = holderIndices[addr] - 1;
        uint256 lastIndex = shareholders.length - 1;
        address lastHolder = shareholders[lastIndex];
        // overwrite the addr's slot with the last shareholder
        shareholders[holderIndex] = lastHolder;
        // also copy over the index
        holderIndices[lastHolder] = holderIndices[addr];
        // trim the shareholders array (which drops the last entry)
        shareholders.length--;
        // and zero out the index for addr
        holderIndices[addr] = 0;
        //Decrease the country count
        uint16 country = identityRegistry.investorCountry(addr);
        countryShareHolders[country]--;
    }

    function getShareholderCountByCountry(uint16 index) public view returns (uint) {
        return countryShareHolders[index];
    }

    /**
     *  Checks to see if the supplied address was superseded.
     *  @param addr The address to check
     *  @return true if the supplied address was superseded by another address.
     */
    function isSuperseded(address addr)
        public
        view
        onlyOwner
        returns (bool)
    {
        return cancellations[addr] != address(0);
    }

    /**
     *  Gets the most recent address, given a superseded one.
     *  Addresses may be superseded multiple times, so this function needs to
     *  follow the chain of addresses until it reaches the final, verified address.
     *  @param addr The superseded address.
     *  @return the verified address that ultimately holds the share.
     */
    function getCurrentFor(address addr)
        public
        view
        onlyOwner
        returns (address)
    {
        return findCurrentFor(addr);
    }

    /**
     *  Recursively find the most recent address given a superseded one.
     *  @param addr The superseded address.
     *  @return the verified address that ultimately holds the share.
     */
    function findCurrentFor(address addr)
        internal
        view
        returns (address)
    {
        address candidate = cancellations[addr];
        if (candidate == address(0)) {
            return addr;
        }
        return findCurrentFor(candidate);
    }

    /**
     *  Sets an address frozen status for this token.
     *  @param addr The address for which to update frozen status
     *  @param freeze Frozen status of the address
     */
    function setAddressFrozen(address addr, bool freeze)
    external
    onlyAgent {
        frozen[addr] = freeze;

        emit AddressFrozen(addr, freeze, msg.sender);
    }

    /**
     *  Freezes token amount specified for given address.
     *  @param addr The address for which to update freezed tokens
     *  @param amount Amount of Tokens to be freezed
     */
    function freezePartialTokens(address addr, uint256 amount)
        onlyAgent
        external
    {
        uint256 balance = balanceOf(addr);
        require(balance >= freezedTokens[addr]+amount, 'Amount exceeds available balance');
        freezedTokens[addr] += amount;
        emit TokensFreezed(addr, amount);
    }
    
    /**
     *  Unfreezes token amount specified for given address
     *  @param addr The address for which to update freezed tokens
     *  @param amount Amount of Tokens to be unfreezed
     */
    function unfreezePartialTokens(address addr, uint256 amount)
        onlyAgent
        external
    {
        require(freezedTokens[addr] >= amount, 'Amount should be less than or equal to freezed tokens');
        freezedTokens[addr] -= amount;
        emit TokensUnfreezed(addr, amount);
    }

    //Identity registry setter.
    function setIdentityRegistry(address _identityRegistry) public onlyOwner {
        identityRegistry = IIdentityRegistry(_identityRegistry);
        emit IdentityRegistryAdded(_identityRegistry);
    }

    function setCompliance(address _compliance) public onlyOwner {
        compliance = ICompliance(_compliance);
        emit ComplianceAdded(_compliance);
    }

    uint256[]  claimTopics;
    bytes32[]  lostAddressClaimIds;
    bytes32[]  newAddressClaimIds;
    uint256 foundClaimTopic;
    uint256 scheme;
    address issuer;
    bytes  sig;
    bytes  data;

    function recoveryAddress(address wallet_lostAddress, address wallet_newAddress, address onchainID) public onlyAgent {
        require(holderIndices[wallet_lostAddress] != 0 && holderIndices[wallet_newAddress] == 0);
        require(identityRegistry.contains(wallet_lostAddress), "wallet should be in the registry");

        Identity _onchainID = Identity(onchainID);

        // Check if the token issuer/Tokeny has the management key to the onchainID
        bytes32 _key = keccak256(abi.encode(msg.sender));

        if(_onchainID.keyHasPurpose(_key, 1)) {
            // Burn tokens on the lost wallet
            uint investorTokens = balanceOf(wallet_lostAddress);
            _burn(wallet_lostAddress, investorTokens);

            // Remove lost wallet management key from the onchainID
            bytes32 lostWalletkey = keccak256(abi.encode(wallet_lostAddress));
            if (_onchainID.keyHasPurpose(lostWalletkey, 1)) {
                uint256[] memory purposes = _onchainID.getKeyPurposes(lostWalletkey);
                for(uint _purpose = 0; _purpose <= purposes.length; _purpose++){
                    if(_purpose != 0)
                        _onchainID.removeKey(lostWalletkey, _purpose);
                }
                // _onchainID.removeKey(lostWalletkey);
            }

            // Add new wallet to the identity registry and link it with the onchainID
            identityRegistry.registerIdentity(wallet_newAddress, _onchainID, identityRegistry.investorCountry(wallet_lostAddress));

            // Remove lost wallet from the identity registry
            identityRegistry.deleteIdentity(wallet_lostAddress);

            cancellations[wallet_lostAddress] = wallet_newAddress;
        	uint256 holderIndex = holderIndices[wallet_lostAddress] - 1;
        	shareholders[holderIndex] = wallet_newAddress;
        	holderIndices[wallet_newAddress] = holderIndices[wallet_lostAddress];
        	holderIndices[wallet_lostAddress] = 0;

            // Mint equivalent token amount on the new wallet
            _mint(wallet_newAddress, investorTokens);

            emit recoverySuccess(wallet_lostAddress, wallet_newAddress, onchainID);

        }
        else {
            emit recoveryFails(wallet_lostAddress, wallet_newAddress, onchainID);
        }
    }
}

// File: browser/MintableAndBurnable.sol

pragma solidity ^0.5.10;



contract MintableAndBurnable is TransferManager {


    /**
     * @notice Improved version of default mint method. Tokens can be minted
     * to an address if only it is a verified address as per the security token.
     * This check will be useful for a complaint crowdsale.
     * Only owner can call.
     *
     * @param _to Address to mint the tokens to.
     * @param _amount Amount of tokens to mint.
     *
     * @return 'True' if minting succesful, 'False' if fails.
     */
    function mint(address _to, uint256 _amount)
        external
        onlyAgent {
        require(identityRegistry.isVerified(_to), "Identity is not verified.");
        _mint(_to, _amount);
        updateShareholders(_to);
    }

    function burn(address account, uint256 value)
        public
        onlyAgent {
        _burn(account, value);
    }
}

// File: browser/UpgradeableToken.sol

pragma solidity ^0.5.0;

/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */




contract UpgradeableToken is MintableAndBurnable {
    // Contract or person who can set the upgrade path.
    address public upgradeMaster;
    
    // Boolean value needs to be true to start upgrades
    bool private upgradesAllowed;

    // The next contract where the tokens will be migrated.
    TokenUpgrader public tokenUpgrader;

    // How many tokens we have upgraded by now.
    uint public totalUpgraded;

    /**
    * Upgrade states.
    * - NotAllowed: The child contract has not reached a condition where the upgrade can begin
    * - Waiting: Token allows upgrade, but we don't have a new token version
    * - ReadyToUpgrade: The token version is set, but not a single token has been upgraded yet
    * - Upgrading: Token upgrader is set and the balance holders can upgrade their tokens
    */
    enum UpgradeState { NotAllowed, Waiting, ReadyToUpgrade, Upgrading }

    // Somebody has upgraded some of his tokens.
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

    // New token version available.
    event TokenUpgraderIsSet(address _newToken);

    modifier onlyUpgradeMaster {
        // Only a master can designate the next token
        require(msg.sender == upgradeMaster);
        _;
    }

    modifier notInUpgradingState {
        // Upgrade has already begun for token
        require(getUpgradeState() != UpgradeState.Upgrading);
        _;
    }

    // Do not allow construction without upgrade master set.
    constructor(address _upgradeMaster) public {
        upgradeMaster = _upgradeMaster;
    }

    // set a token upgrader
    function setTokenUpgrader(address _newToken)
        external
        onlyUpgradeMaster
        notInUpgradingState
    {
        require(canUpgrade());
        require(_newToken != address(0));


        //---------------------------------------
        tokenUpgrader = TokenUpgrader(_newToken);

        // Handle bad interface
        require(tokenUpgrader.isTokenUpgrader());

        // Make sure that token supplies match in source and target
        require(tokenUpgrader.originalSupply() == totalSupply());
    
        emit TokenUpgraderIsSet(address(tokenUpgrader));
    }

    // Allow the token holder to upgrade some of their tokens to a new contract.
    function upgrade(uint _value) external {
        UpgradeState state = getUpgradeState();
        
        // Check upgrate state 
        require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);
        // Validate input value
        require(_value != 0);

        //balances[msg.sender] = balances[msg.sender].sub(_value);
        // Take tokens out from circulation
        //totalSupply_ = totalSupply_.sub(_value);
        //the _burn method emits the Transfer event
        _burn(msg.sender, _value);   //defined in erc20

        totalUpgraded = totalUpgraded.add(_value);

        // Token Upgrader reissues the tokens
        //_mint(msg.sender, _value);
        tokenUpgrader.upgradeFrom(msg.sender, _value);
        emit Upgrade(msg.sender, address(tokenUpgrader), _value);
    }

    /**
    * Change the upgrade master.
    * This allows us to set a new owner for the upgrade mechanism.
    */
    function setUpgradeMaster(address _newMaster) external onlyUpgradeMaster {
        require(_newMaster != address(0));
        upgradeMaster = _newMaster;
    }

    // To be overriden to add functionality
    function allowUpgrades() external onlyUpgradeMaster () {
        upgradesAllowed = true;
    }

    // To be overriden to add functionality
    function rejectUpgrades() external onlyUpgradeMaster () {
        require(!(totalUpgraded > 0));
        upgradesAllowed = false;
    }

    // Get the state of the token upgrade.
    function getUpgradeState() public view returns(UpgradeState) {
        if (!canUpgrade()) return UpgradeState.NotAllowed;
        else if (address(tokenUpgrader) == address(0)) return UpgradeState.Waiting;
        else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else return UpgradeState.Upgrading;
    }

    // To be overriden to add functionality
    function canUpgrade() public view returns(bool) {
        return upgradesAllowed;
    }
}

// File: browser/Token.sol

pragma solidity ^0.5.10;



contract Token is UpgradeableToken {
    string public name = "FLYT TOKEN";
    string public symbol = "FLYT";
    uint8 public decimals = 0;
    string public version = "1.2";
    address public onchainID = 0x0000000000000000000000000000000000000000;
    
    event UpdatedTokenInformation(
		string newName,
		string newSymbol,
		uint8 newDecimals,
		string newVersion,
		address newOnchainID
	);

    constructor(
        address _identityRegistry,
        address _compliance,
        address _upgradeMaster
		)
        public
		TransferManager(_identityRegistry, _compliance)
		UpgradeableToken(_upgradeMaster)
    {}

    /**
    * Owner can update token information here
    */
    function setTokenInformation(
		string calldata _name,
		string calldata _symbol,
		uint8 _decimals,
		string calldata _version,
		address _onchainID
		) external onlyOwner {

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        version = _version;
		onchainID = _onchainID;

        emit UpdatedTokenInformation(name, symbol, decimals, version, onchainID);
    }
}

