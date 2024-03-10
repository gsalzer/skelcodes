// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

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
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;



/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

// File: contracts/interfaces/ITransferManager.sol

pragma solidity ^0.5.12;

/**
* @title Base transfer manager interface
*/
interface ITransferManager {

    /**
    * @notice Checks whether transfer approved or not
    * @param _spender Address of the spender
    * @param _from The address to transfer from
    * @param _to The address to transfer to
    * @param _amount Amount of tokens for the transfer
    */
    function isApproved(address _spender, address _from, address _to, uint256 _amount) external returns (bool);

}

// File: contracts/libraries/AddressList.sol

pragma solidity ^0.5.12;

/**
 * @title Util for working with an array of addresses
 * @dev lib doesn't throw errors for already added or not found addresses
 * @dev see tests for WhitelistTransferManager
 */
library AddressList {

    string private constant ERROR_INVALID_ADDRESS = "Invalid address";

    struct Data {
        bool added;
        uint248 index;
    }

    /**
    * @notice Adds the address to the given list
    * @param _address Address to be added
    * @param _data Mapping of AddressData
    * @param _list Array of addresses
    */
    function addTo(
        address _address,
        mapping(address => Data) storage _data,
        address[] storage _list
    )
        internal
    {
        require(_address != address(0), ERROR_INVALID_ADDRESS);

        if (!_data[_address].added) {
            _data[_address] = Data({
                added: true,
                index: uint248(_list.length)
                });
            _list.push(_address);
        }
    }

    /**
    * @notice Removes the address from the given list
    * @param _address Address to be removed
    * @param _data Mapping of AddressData
    * @param _list Array of addresses
    */
    function removeFrom(
        address _address,
        mapping(address => Data) storage _data,
        address[] storage _list
    )
        internal
    {
        require(_address != address(0), ERROR_INVALID_ADDRESS);

        if (_data[_address].added) {
            uint248 index = _data[_address].index;
            if (index != _list.length - 1) {
                _list[index] = _list[_list.length - 1];
                _data[_list[index]].index = index;
            }
            _list.length--;
            delete _data[_address];
        }
    }

}

// File: openzeppelin-solidity/contracts/access/Roles.sol

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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

// File: contracts/interfaces/IPermissionManager.sol

pragma solidity ^0.5.12;

/**
* @title Permission manager
*/
interface IPermissionManager {

    function hasRole(address _user, bytes32 _role) external view returns (bool);

    function hasRoles(address _user, bytes32[] calldata _roles) external view returns (bool);

    function addRole(address _user, bytes32 _role) external;

    function removeRole(address _user, bytes32 _role) external;

    function getRoles() external returns (bytes32[] memory);

}

// File: contracts/role/AllowableStorage.sol

pragma solidity ^0.5.12;


/**
 * @title Storage for Allowable
 */
contract AllowableStorage {

    string internal constant ERROR_ACCESS_DENIED = "Access is denied";
    string internal constant ERROR_INVALID_ADDRESS = "Invalid address";
    string internal constant ERROR_IS_NOT_ALLOWED = "Is not allowed";
    string internal constant ERROR_ROLE_NOT_FOUND = "Role not found";
    string internal constant ERROR_STOPPED = "Contract is stopped";
    string internal constant ERROR_NOT_STOPPED = "Contract is not stopped";

    string internal constant ERROR_ACTION_WAS_NOT_REQUESTED = "Action wasn't requested";
    string internal constant ERROR_ACTION_WAS_REQUESTED_BY_SENDER = "Action was requested by a sender";

    address _owner = address(0x00);

    //list of the system roles
    bytes32[] roleNames;

    //map of users for the given role
    mapping(bytes32 => mapping(address => AddressList.Data)) roleUserData;
    //list of users for the given role
    mapping(bytes32 => address[]) roleUsers;

    //attached permission manager
    address permissionManager = address(0x00);

    //Initially, roles can be added without an approval
    bool roleApproval = false;

    bool transferOwnershipApproval = false;

    bool stopped = false;

    //newOwner => initiator
    mapping(address => address) transferOwnershipInitiator;

    //user => role => initiator
    mapping(address => mapping(bytes32 => address)) addRoleInitiators;

    //user => role => initiator
    mapping(address => mapping(bytes32 => address)) removeRoleInitiators;

    //List of admin roles
    bytes32[] adminRoles;

    address stopInitiator = address(0x00);

    address startInitiator = address(0x00);

    address configurator = address(0x00);

}

// File: contracts/libraries/linked/AllowableLib.sol

pragma solidity ^0.5.12;


library AllowableLib {
    using AddressList for address;

    string internal constant ERROR_ROLE_NOT_FOUND = "Role not found";

    string internal constant ERROR_ACCESS_DENIED = "Access is denied";
    string internal constant ERROR_ACTION_WAS_NOT_REQUESTED = "Action wasn't requested";
    string internal constant ERROR_ACTION_WAS_REQUESTED_BY_SENDER = "Action was requested by a sender";

    event RoleAdded(address indexed _user, bytes32 _role);
    event RoleRemoved(address indexed _user, bytes32 _role);

    event RoleAddingRequested(address indexed _user, bytes32 _role);
    event RoleRemovingRequested(address indexed _user, bytes32 _role);

    /**
    * @notice Adds given role to the user
    * @param _user Address of user wallet
    * @param _role Role name
    * param _withApproval Flag whether we need an approval
    */
    function addRole(
        address _user,
        bytes32 _role,
        bool _withApproval,
        bool _withSameRole,
        bytes32[] storage roleNames,
        mapping(bytes32 => mapping(address => AddressList.Data)) storage roleUserData,
        mapping(bytes32 => address[]) storage roleUsers,
        mapping(address => mapping(bytes32 => address)) storage addRoleInitiators
    )
        public
    {
        if (_withApproval) {
            _checkRoleLevel(_role, _withSameRole, roleUserData);
            _checkInitiator(addRoleInitiators[_user][_role]);
        }
        require(isExists(_role, roleNames), ERROR_ROLE_NOT_FOUND);
        _user.addTo(roleUserData[_role], roleUsers[_role]);
        emit RoleAdded(_user, _role);
        if (_withApproval) {
            delete addRoleInitiators[_user][_role];
        }
    }

    /**
    * @notice Requests to add given role to the user
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function addRoleRequest(
        address _user,
        bytes32 _role,
        bool _withSameRole,
        mapping(bytes32 => mapping(address => AddressList.Data)) storage roleUserData,
        mapping(address => mapping(bytes32 => address)) storage addRoleInitiators
    )
        public
    {
        _checkRoleLevel(_role, _withSameRole, roleUserData);
        addRoleInitiators[_user][_role] = msg.sender;
        emit RoleAddingRequested(_user, _role);
    }

    /**
    * @notice Removes given role from the user
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function removeRole(
        address _user,
        bytes32 _role,
        bool _withApproval,
        bool _withSameRole,
        bytes32[] storage roleNames,
        mapping(bytes32 => mapping(address => AddressList.Data)) storage roleUserData,
        mapping(bytes32 => address[]) storage roleUsers,
        mapping(address => mapping(bytes32 => address)) storage removeRoleInitiators
    )
        public
    {
        if (_withApproval) {
            _checkRoleLevel(_role, _withSameRole, roleUserData);
            _checkInitiator(removeRoleInitiators[_user][_role]);
        }
        require(isExists(_role, roleNames), ERROR_ROLE_NOT_FOUND);
        _user.removeFrom(roleUserData[_role], roleUsers[_role]);
        emit RoleRemoved(_user, _role);
        if (_withApproval) {
            delete removeRoleInitiators[_user][_role];
        }
    }

    /**
    * @notice Requests to remove given role to the user
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function removeRoleRequest(
        address _user,
        bytes32 _role,
        bool _withSameRole,
        mapping(bytes32 => mapping(address => AddressList.Data)) storage roleUserData,
        mapping(address => mapping(bytes32 => address)) storage removeRoleInitiators
    )
        public
    {
        _checkRoleLevel(_role, _withSameRole, roleUserData);
        removeRoleInitiators[_user][_role] = msg.sender;
        emit RoleRemovingRequested(_user, _role);
    }

    /**
    * @notice Adds given role to the supported role list
    * @param _role Role name
    */
    function addSystemRole(
        bytes32 _role,
        bytes32[] storage roleNames
    )
        public
    {
        if (!isExists(_role, roleNames)) {
            roleNames.push(_role);
        }
    }

    /**
    * @notice Checks whether the role has been already added
    * @param _role Role name
    */
    function isExists(
        bytes32 _role,
        bytes32[] storage roleNames
    )
        private
        view
        returns (bool)
    {
        for (uint i = 0; i < roleNames.length; i++) {
            if (_role == roleNames[i]) {
                return true;
            }
        }
        return false;
    }

    /**
    * @notice Checks whether the message sender has the same role
    * @param _role Role to be added
    * @param _withSameRole A flag whether we need to do role level check
    */
    function _checkRoleLevel(
        bytes32 _role,
        bool _withSameRole,
        mapping(bytes32 => mapping(address => AddressList.Data)) storage roleUserData
    )
        internal
        view
    {
        if (_withSameRole) {
            require(roleUserData[_role][msg.sender].added, ERROR_ACCESS_DENIED);
        }
    }

    /**
    * @notice Validates initiator address
    * @param _initiator Address of the action initiator
    * @dev Checks whether an action was requested and by different address
    */
    function _checkInitiator(address _initiator) internal view {
        require(_initiator != address(0), ERROR_ACTION_WAS_NOT_REQUESTED);
        require(_initiator != msg.sender, ERROR_ACTION_WAS_REQUESTED_BY_SENDER);
    }

}

// File: contracts/role/AllowableModifiers.sol

pragma solidity ^0.5.12;







/**
 * @title Allowable Modifiers
 * @dev Provides role-based access control
 */
contract AllowableModifiers is AllowableStorage  {
    using AddressList for address;

    bytes32 internal constant ROLE_INVENIAM_ADMIN = "INVENIAM_ADMIN";

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), ERROR_ACCESS_DENIED);
        _;
    }

    modifier onlyRole(bytes32 _role) {
        require(_hasRole(msg.sender, _role), ERROR_ACCESS_DENIED);
        _;
    }

    modifier onlyRoleStrict(bytes32 _role) {
        require(_hasRoleStrict(msg.sender, _role), ERROR_ACCESS_DENIED);
        _;
    }

    modifier onlyRoles(bytes32[] memory _roles) {
        require(_hasRoles(msg.sender, _roles), ERROR_ACCESS_DENIED);
        _;
    }

    modifier onlyAdmin {
        require(_hasRoles(msg.sender, adminRoles), ERROR_ACCESS_DENIED);
        _;
    }

    modifier notStopped() {
        require(!stopped, ERROR_STOPPED);
        _;
    }

    modifier isStopped() {
        require(stopped, ERROR_NOT_STOPPED);
        _;
    }

    /**
    * @notice Checks whether the user has an appropriate role or an owner
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function _hasRole(address _user, bytes32 _role) internal view returns (bool) {
        return isOwner() || _hasRoleStrict(_user, _role);
    }

    /**
    * @notice Checks whether the user has an appropriate role
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function _hasRoleStrict(address _user, bytes32 _role) internal view returns (bool) {
        return roleUserData[_role][_user].added
        || (permissionManager != address(0) && IPermissionManager(permissionManager).hasRole(_user, _role));
    }

    /**
    * @notice Checks whether the user has at least one role from the given list or an owner
    * @param _user Address of user wallet
    * @param _roles Array of role names
    */
    function _hasRoles(address _user, bytes32[] memory _roles) internal view returns (bool) {
        if (isOwner()) {
            return true;
        }
        return _hasLocalRoles(_user, _roles)
        || (permissionManager != address(0) && IPermissionManager(permissionManager).hasRoles(_user, _roles));
    }

    /**
    * @notice Checks whether the user has at least one role from the given list (current contract storage)
    * @param _user Address of user wallet
    * @param _roles Array of role names
    */
    function _hasLocalRoles(address _user, bytes32[] memory _roles) internal view returns (bool) {
        for (uint i = 0; i < _roles.length; i++) {
            bytes32 role = _roles[i];
            if (roleUserData[role][_user].added) {
                return true;
            }
        }
        return false;
    }

}

// File: contracts/proxy/FunctionProxy.sol

pragma solidity ^0.5.12;

/**
* @title Base Proxy for delegate function calls
*/
contract FunctionProxy {

    string private constant ERROR_IMPLEMENTATION_NOT_FOUND = "Implementation not found";

    /**
    * @dev Returns an address of the implementation.
    */
    function _getImplementation() internal view returns (address) {
        return address(0);
    }

    /**
     * @dev Fallback function allowing to perform a delegatecall
     * Returns whatever the implementation call returns
     */
    function () external {
        address implementation = _getImplementation();
        require(implementation != address(0), ERROR_IMPLEMENTATION_NOT_FOUND);

        assembly {
            let pointer := mload(0x40)
            calldatacopy(pointer, 0, calldatasize)
            let result := delegatecall(gas, implementation, pointer, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(pointer, 0, size)

            switch result
            case 0 { revert(pointer, size) }
            default { return(pointer, size) }
        }
    }

}

// File: contracts/role/Allowable.sol

pragma solidity ^0.5.12;








/**
 * @title Allowable
 * @dev Provides role-based access control
 */
contract Allowable is AllowableModifiers, FunctionProxy {
    using AddressList for address;

    bytes32 private constant ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN = "INDIVIDUAL_ISSUE_TOKEN_ADMIN";

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event RoleAdded(address indexed _user, bytes32 _role);
    event RoleRemoved(address indexed _user, bytes32 _role);

    event RoleAddingRequested(address indexed _user, bytes32 _role);
    event RoleRemovingRequested(address indexed _user, bytes32 _role);

    function initRoleApproval() public {
        roleApproval = true;
    }

    /**
    * @notice Adds given role to the supported role list
    * @param _role Role name
    */
    function _addSystemRole(bytes32 _role) internal {
        AllowableLib.addSystemRole(_role, roleNames);
    }

    /**
    * @notice Adds given role to the user
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function addRole(address _user, bytes32 _role) public notStopped onlyAdmin {
        _addRole(_user, _role);
    }

    /**
    * @notice Adds given role to the users
    * @param _users List of Addresses
    * @param _role Role name
    */
    function addRoles(address[] memory _users, bytes32 _role) public notStopped onlyAdmin {
        for (uint i = 0; i < _users.length; i++) {
            _addRole(_users[i], _role);
        }
    }

    /**
    * @notice Adds given role to the user
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function _addRole(address _user, bytes32 _role) private {
        bool withApproval = _addRoleWithApproval(_user, _role);
        bool withSameRole = _withSameRole(_role);
        AllowableLib.addRole(_user, _role, withApproval, withSameRole, roleNames, roleUserData, roleUsers, addRoleInitiators);
    }

    /**
    * @notice Requests to add given role to the user
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function addRoleRequest(address _user, bytes32 _role) public notStopped onlyAdmin {
        _addRoleRequest(_user, _role);
    }

    /**
    * @notice Requests to add given role to the user
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function _addRoleRequest(address _user, bytes32 _role) private {
        bool withSameRole = _withSameRole(_role);
        AllowableLib.addRoleRequest(_user, _role, withSameRole, roleUserData, addRoleInitiators);
    }

    /**
    * @notice Removes given role from the user
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function removeRole(address _user, bytes32 _role) public notStopped onlyAdmin {
        _removeRole(_user, _role);
    }

    /**
    * @notice Removes given role from the user
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function _removeRole(address _user, bytes32 _role) private {
        bool withApproval = _removeRoleWithApproval(_user, _role);
        bool withSameRole = _withSameRole(_role);
        AllowableLib.removeRole(_user, _role, withApproval, withSameRole, roleNames, roleUserData, roleUsers, removeRoleInitiators);
    }

    /**
    * @notice Requests to remove given role to the user
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function removeRoleRequest(address _user, bytes32 _role) public notStopped onlyAdmin {
        _removeRoleRequest(_user, _role);
    }

    /**
    * @notice Requests to remove given role to the user
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function _removeRoleRequest(address _user, bytes32 _role) private {
        bool withSameRole = _withSameRole(_role);
        AllowableLib.removeRoleRequest(_user, _role, withSameRole, roleUserData, removeRoleInitiators);
    }

    /**
    * @notice Returns whether adding role should be approved by user with the same role
    */
    function _withSameRole(bytes32 _role) private pure returns (bool) {
        return _role == ROLE_INVENIAM_ADMIN;
    }

    /**
    * @notice Returns whether adding role should be approved
    * @dev Approval makes sense if we have at least one admin
    */
    function _addRoleWithApproval(address /*_user*/, bytes32 /*_role*/) internal view returns (bool) {
        return roleApproval && _getAdminCount() > 0;
    }

    /**
    * @notice Returns whether removing role should be approved
    * @dev Approval makes sense if we have at least one admin (after removal)
    */
    function _removeRoleWithApproval(address /*_user*/, bytes32 _role) internal view returns (bool) {
        uint adminCount = _getAdminCount();
        //if role to be removed is an admin role, we won't use it for an approval
        if (_role == adminRoles[0] || _role == adminRoles[1]) {
            adminCount--;
        }
        return roleApproval && adminCount > 0;
    }

    /**
    * @notice Calculates the number of current admins
    * @dev Supposes that we have only 2 levels of admin roles
    */
    function _getAdminCount() private view returns (uint) {
        uint adminCount;
        if (adminRoles.length == 2) {
            adminCount = roleUsers[adminRoles[0]].length + roleUsers[adminRoles[1]].length;
        }
        return adminCount;
    }

    /**
    * @notice Gets list of the system roles
    */
    function getRoles() public view returns (bytes32[] memory) {
        return roleNames;
    }

    /**
    * @notice Gets users which have the given role
    * @param _role Role name
    */
    function getUsersByRole(bytes32 _role) public view returns (address[] memory) {
        return roleUsers[_role];
    }

    /**
     * @dev Sets permission manager
     * @param _permissionManager Address of the permission manager
     */
    function setPermissionManager(address _permissionManager) public notStopped onlyAdmin {
        _setPermissionManager(_permissionManager);
    }

    function _setPermissionManager(address _permissionManager) private {
        permissionManager = _permissionManager;
    }

    /**
    * @notice Returns permission manager
    */
    function getPermissionManager() public view returns (address) {
        return permissionManager;
    }

    /**
     * @notice Allows the current owner to transfer control of the contract to a newOwner.
     * @dev Only first transfer should be without an approval
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public notStopped onlyOwner {
        if (transferOwnershipApproval) {
            transferOwnershipInitiator[newOwner] = msg.sender;
        } else {
            transferOwnershipApproval = true;
            _transferOwnership(newOwner);
        }
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) private {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @notice Approve transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function approveTransferOwnership(address newOwner) public notStopped onlyRoleStrict(ROLE_INVENIAM_ADMIN) {
        _checkInitiator(transferOwnershipInitiator[newOwner]);
        _transferOwnership(newOwner);
        delete transferOwnershipInitiator[newOwner];
    }

    /**
     * @notice Request stop of a contract
     */
    function stopRequest() public notStopped onlyRole(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN) {
        stopInitiator = msg.sender;
    }

    /**
     * @notice Stops a contract
     * @dev All transactions (except startRequest and start) will be reverted
     */
    function stop() public notStopped onlyRoleStrict(ROLE_INVENIAM_ADMIN) {
        _checkInitiator(stopInitiator);
        stopped = true;
        delete stopInitiator;
    }

    /**
     * @notice Request start of a contract
     * @dev Can be executed only for stopped contracts
     */
    function startRequest() public isStopped onlyRole(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN) {
        startInitiator = msg.sender;
    }

    /**
     * @notice Starts a contract
     * @dev Can be executed only for stopped contracts
     */
    function start() public isStopped onlyRoleStrict(ROLE_INVENIAM_ADMIN) {
        _checkInitiator(startInitiator);
        stopped = false;
        delete startInitiator;
    }

    /**
    * @notice Validates initiator address
    * @param _initiator Address of the action initiator
    * @dev Checks whether an action was requested and by different address
    */
    function _checkInitiator(address _initiator) private view {
        require(_initiator != address(0), ERROR_ACTION_WAS_NOT_REQUESTED);
        require(_initiator != msg.sender, ERROR_ACTION_WAS_REQUESTED_BY_SENDER);
    }

    /**
    * @dev Returns an address of the 'configurator' implementation.
    */
    function _getImplementation() internal view returns (address) {
        return configurator;
    }

}

// File: contracts/interfaces/IDocumentManager.sol

pragma solidity ^0.5.12;

/**
* @title Interface of a contract for parsing and storing document data
*/
interface IDocumentManager {

    event DocumentAdded(
        string indexed _document,
        string _uri,
        string indexed _checksum,
        string _checksumAlgo,
        string _timestamp,
        string _figi,
        string _individualId
    );

    /**
    * @dev Sets fields separator
    * @param _separator Separator
    */
    function setFieldSeparator(string calldata _separator) external;

    /**
    * @dev Gets fields separator
    */
    function getFieldSeparator() external view returns (string memory);

    /**
    * @dev Sets store data flag
    * @param _saveData Store data flag
    */
    function setSaveData(bool _saveData) external;

    /**
    * @dev Gets store data flag
    */
    function getSaveData() external view returns (bool);

    /**
    * @dev Attaches document to token
    * @param _symbol Token symbol
    * @param _data string Text message with metadata
    */
    function setDocument(string calldata _symbol, string calldata _data) external;

    /**
    * @dev Gets document data
    * @param _symbol Token symbol
    * @param _id Document ID
    */
    function getDocument(string calldata _symbol, bytes32 _id)
        external
        view
        returns (string memory, string memory, string memory, string memory, string memory, string memory, string memory);

    /**
    * @dev Gets the list of documents' ids
    * @param _symbol Token symbol
    */
    function getDocumentIds(string calldata _symbol) external view returns (bytes32[] memory);

}

// File: contracts/libraries/linked/InveniamTokenLib.sol

pragma solidity ^0.5.12;



library InveniamTokenLib {
    using SafeMath for uint256;
    using AddressList for address;

    string private constant ERROR_INVALID_INDEX = "Index out of bound";
    string private constant ERROR_INVALID_ADDRESS = "Invalid address";
    string private constant ERROR_INVALID_AMOUNT = "Invalid amount";
    string private constant ERROR_AMOUNT_IS_NOT_AVAILABLE = "Amount is not available";

    event TransferRequested(address indexed _from, address indexed _to, uint256 _amount);

    struct HistoryBalance {
        uint40 timestamp;
        uint216 value;
    }

    /**
     * @dev Updates balances history after transfer
     * @param _from The address which you want to send tokens from
     * @param _to The address which you want to transfer to
     */
    function afterTransfer(
        address tokenAddress,
        address _from,
        address _to,
        uint _balanceFrom,
        uint _balanceTo,
        mapping(address => AddressList.Data) storage holderData,
        address[] storage holders,
        mapping(address => HistoryBalance[]) storage historyBalances,
        address[] storage historyHolders
    )
        public
    {
        if (_from != tokenAddress) {
            if (_balanceFrom == 0) {
                _from.removeFrom(holderData, holders);
            }
            if (historyBalances[_from].length == 0) {
                historyHolders.push(_from);
            }
            historyBalances[_from].push(HistoryBalance(uint40(now), uint216(_balanceFrom)));
        }

        if (_to != tokenAddress) {
            if (_balanceTo > 0) {
                _to.addTo(holderData, holders);
            }
            if (historyBalances[_to].length == 0) {
                historyHolders.push(_to);
            }
            historyBalances[_to].push(HistoryBalance(uint40(now), uint216(_balanceTo)));
        }
    }

    /**
     * @dev Update balance history after mint
     * @param _account The account that will receive the created tokens
     * @param _balance The current balance of the account
     */
    function afterMint(
        address _account,
        uint _balance,
        mapping(address => AddressList.Data) storage holderData,
        address[] storage holders,
        mapping(address => HistoryBalance[]) storage historyBalances,
        address[] storage historyHolders
    )
        public
    {
        if (_balance > 0) {
            _account.addTo(holderData, holders);
        }

        if (historyBalances[_account].length == 0) {
            historyHolders.push(_account);
        }
        historyBalances[_account].push(HistoryBalance(uint40(now), uint216(_balance)));
    }

    /**
     * @dev Updates balance history after burn
     * @param _account The account whose tokens will be burnt
     * @param _balance The current balance of the account
     */
    function afterBurn(
        address _account,
        uint _balance,
        mapping(address => AddressList.Data) storage holderData,
        address[] storage holders,
        mapping(address => HistoryBalance[]) storage historyBalances,
        address[] storage historyHolders
    )
        public
    {
        if (_balance == 0) {
            _account.removeFrom(holderData, holders);
        }

        if (historyBalances[_account].length == 0) {
            historyHolders.push(_account);
        }
        historyBalances[_account].push(HistoryBalance(uint40(now), uint216(_balance)));
    }

    /**
     * @dev Requests transfer
     * @param _from The address to transfer from
     * @param _to The address to transfer to
     */
    function requestTransfer(
        address _from,
        address _to,
        uint256 /*_amount*/,
        mapping(address => AddressList.Data) storage senderData,
        address[] storage senders,
        mapping(address => mapping (address => uint256)) storage /*transferBalances*/,
        mapping(address => mapping(address => AddressList.Data)) storage senderToReceiverData,
        mapping(address => address[]) storage senderToReceivers
    )
        public
    {
        if (senderToReceivers[_from].length == 0) {
            _from.addTo(senderData, senders);
        }
        _to.addTo(senderToReceiverData[_from], senderToReceivers[_from]);
    }

    /**
     * @dev Removes accounts from pending transfer list
     * @param _from The address to transfer from
     * @param _to The address to transfer to
     */
    function removeParticipants(
        address _from,
        address _to,
        mapping(address => AddressList.Data) storage senderData,
        address[] storage senders,
        mapping(address => mapping(address => AddressList.Data)) storage senderToReceiverData,
        mapping(address => address[]) storage senderToReceivers
    )
        public
    {
        _to.removeFrom(senderToReceiverData[_from], senderToReceivers[_from]);
        if (senderToReceivers[_from].length == 0) {
            _from.removeFrom(senderData, senders);
        }
    }

    /**
     * @dev Validates transfer according to rules
     * @param _to The address to transfer to
     * @param _amount The amount of the transfer
     * @param _balance The balance of from address
     */
    function validateTransfer(address /*_from*/, address _to, uint256 _amount, uint256 _balance) public pure {
        require(_amount > 0, ERROR_INVALID_AMOUNT);
        require(_amount <= _balance, ERROR_AMOUNT_IS_NOT_AVAILABLE);
        require(_to != address(0), ERROR_INVALID_ADDRESS);
    }

}

// File: contracts/TokenStorage.sol

pragma solidity ^0.5.12;



/**
 * @title Storage for InveniamToken
 */
contract TokenStorage {

    // Declare storage for (pending) transfer requests
    mapping(address => mapping (address => uint256)) transferBalances;

    //attached transfer manager
    address transferManager = address(0x00);

    //current senders list
    mapping(address => AddressList.Data) senderData;
    address[] senders;

    //current receivers list for a given sender
    mapping(address => mapping(address => AddressList.Data)) senderToReceiverData;
    mapping(address => address[]) senderToReceivers;

    //current token holders
    mapping(address => AddressList.Data) holderData;
    address[] holders;

    //history token holders
    mapping(address => InveniamTokenLib.HistoryBalance[]) historyBalances;
    address[] historyHolders;

    //attached document manager
    address documentManager = address(0x00);

    //Flag whether pending balances should be saved
    bool savePendingBalances = false;

    //Flag whether holders history should be saved
    bool saveHoldersHistory = false;

    //Initially, a forced transfer can be done without an approval
    bool forceTransferApproval = false;

    address allowable = address(0x00);

    //from => to => amount => initiator
    mapping(address => mapping(address => mapping(uint256 => address))) forceTransferInitiators;

}

// File: contracts/interfaces/ITokenConfigurator.sol

pragma solidity ^0.5.12;

/**
* @title Interface for token configurator
*/
interface ITokenConfigurator {

    /**
     * @dev Get balance for pending transfer
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     */
    function getPendingBalance(address _from, address _to) external view returns (uint256);

    /**
     * @dev Returns sender addresses
     */
    function getSenders() external view returns (address[] memory);

    /**
     * @dev Returns receivers addresses
     */
    function getReceiversBySender(address _sender) external view returns (address[] memory);

    /**
     * @dev Returns holder addresses
     * @dev use balanceOf to get the balance for each holder
     */
    function getHolders() external view returns (address[] memory);

    /**
     * @dev Returns history holder addresses
     */
    function getHistoryHolders() external view returns (address[] memory);

    /**
     * @dev Returns length of the history for a given account
     */
    function getHistoryLength(address _account) external view returns (uint);

    /**
     * @dev Returns history balance (timestamp, value) for a given account and index
     */
    function getHistoryBalance(address _account, uint _index) external view returns (uint40, uint216);

    /**
     * @dev Sets transfer manager
     * @dev set 0x00 if you need to remove transfer manager
     * @param _transferManager Address of the transfer manager
     */
    function setTransferManager(address _transferManager) external;

    /**
     * @dev Returns address of the transfer manager
     */
    function getTransferManager() external view returns (address);

    /**
     * @dev Set document manager
     * @dev set 0x00 if you need to remove document manager
     * @param _documentManager Address of the document manager
     */
    function setDocumentManager(address _documentManager) external;

    /**
     * @dev Return address of the document manager
     */
    function getDocumentManager() external view returns (address);

    /**
    * @dev Sets save pending balances flag
    * @param _savePendingBalances Flag whether pending balances should be saved
    */
    function setSavePendingBalances(bool _savePendingBalances) external;

    /**
    * @dev Gets save pending balances flag
    */
    function getSavePendingBalances() external view returns (bool);

    /**
    * @dev Sets holders history flag
    * @param _saveHoldersHistory Flag whether holders history should be saved
    */
    function setSaveHoldersHistory(bool _saveHoldersHistory) external;

    /**
    * @dev Gets holders history flag
    */
    function getSaveHoldersHistory() external view returns (bool);

    function initForceTransferApproval() external;

}

// File: contracts/InveniamToken.sol

pragma solidity ^0.5.12;











/**
 * @title ERC20 based implementation with:
 * 1) off-chain transfer verification;
 * 2) owner only mint/burn functionality;
 *
 * @dev Main Inveniam Token implementation
 */
contract InveniamToken is AllowableModifiers, TokenStorage, ERC20, ERC20Detailed, FunctionProxy {

    bytes32 private constant ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN = "INDIVIDUAL_ISSUE_TOKEN_ADMIN";

    string private constant ERROR_INVALID_AMOUNT = "Invalid amount";
    string private constant ERROR_AMOUNT_IS_NOT_AVAILABLE = "Amount is not available";
    string private constant ERROR_AMOUNT_IS_NOT_ALLOWED = "Amount is not allowed";
    string private constant ERROR_INVALID_TOTAL_SUPPLY = "New supply is equal to the current supply";
    string private constant ERROR_TRANSFER_NOT_FOUND = "Pending transfer not found";

    event TransferRequested(address indexed _from, address indexed _to, uint256 _amount);

    event TransferApproved(address indexed _from, address indexed _to, uint256 _amount);

    event TransferRejected(address indexed _from, address indexed _to, uint256 _amount);

    event SupplyChanged(uint256 _delta, uint256 _totalSupply);

    event ForcedTransfer(address indexed _from, address indexed _to, uint256 _amount);

    event ForceTransferRequested(address indexed _from, address indexed _to, uint256 _amount);

    event DocumentAdded(
        string indexed _document,
        string _uri,
        string indexed _checksum,
        string _checksumAlgo,
        string _timestamp,
        string _figi,
        string _individualId
    );

    event RawDocumentAdded(string _data);

    /**
    * @dev Creates token with given data
    * @param _symbol Token symbol
    * @param _name Token name
    * @param _decimals Token decimals
    * @param _totalSupply Initial token supply
    * @param _tokenOwner Owner of the token
    * @param _tokenRegistry Token Registry
    */
    constructor (
        string memory _symbol,
        string memory _name,
        uint8 _decimals,
        uint256 _totalSupply,
        address _tokenOwner,
        address _tokenRegistry,
        bool _saveHoldersHistory,
        address _allowable,
        address _configurator
    )
        ERC20Detailed(_name, _symbol, _decimals)
        public
    {
        saveHoldersHistory = _saveHoldersHistory;
        allowable = _allowable;
        configurator = _configurator;
        if (_totalSupply > 0) {
            _mint(_tokenOwner, _totalSupply);
        }

        AllowableLib.addSystemRole(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN, roleNames);
        AllowableLib.addSystemRole(ROLE_INVENIAM_ADMIN, roleNames);
        //we need to add this role for initial token set up
        //will be removed after it
        _addRole(_tokenRegistry, ROLE_INVENIAM_ADMIN);

        adminRoles.push(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN);
        adminRoles.push(ROLE_INVENIAM_ADMIN);
    }

    /**
    * @notice Adds given role to the user
    * @param _user Address of user wallet
    * @param _role Role name
    */
    function _addRole(address _user, bytes32 _role) private {
        AllowableLib.addRole(_user, _role, false, false, roleNames, roleUserData, roleUsers, addRoleInitiators);
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _amount The amount to be transferred.
    */
    function transfer(address _to, uint256 _amount) public notStopped returns (bool) {
        _validateTransfer(msg.sender, _to, _amount);

        if (_isApproved(msg.sender, msg.sender, _to, _amount)) {
            super.transfer(_to, _amount);
            emit TransferApproved(msg.sender, _to, _amount);
        } else {
            super.transfer(address(this), _amount);
            _requestTransfer(msg.sender, _to, _amount);
        }
        return true;
    }

    /**
     * @dev Transfer tokens from one specified address to another
     * @param _from The address which you want to send tokens from
     * @param _to The address which you want to transfer to
     * @param _amount The amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _amount) public notStopped returns (bool) {
        _validateTransfer(_from, _to, _amount);
        require(_amount <= allowance(_from, msg.sender), ERROR_AMOUNT_IS_NOT_ALLOWED);

        if (_isApproved(msg.sender, _from, _to, _amount)) {
            super.transferFrom(_from, _to, _amount);
            emit TransferApproved(_from, _to, _amount);
        } else {
            super.transferFrom(_from, address(this), _amount);
            _requestTransfer(_from, _to, _amount);
        }
        return true;
    }

    /**
     * @dev Approves transfer of tokens
     * The approveTransfer method is used for a withdraw workflow, allowing the owner of the contracts to approve
     * tokens on your behalf, for example to "deposit" to a contract address and/or to charge
     * fees in sub-currencies;
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _amount The amount to be transferred.
     */
    function approveTransfer(address _from, address _to, uint256 _amount) external notStopped onlyAdmin {
        require(_amount > 0, ERROR_INVALID_AMOUNT);
        require(_amount <= transferBalances[_from][_to], ERROR_AMOUNT_IS_NOT_AVAILABLE);

        transferBalances[_from][_to] = transferBalances[_from][_to].sub(_amount);
        if (transferBalances[_from][_to] == 0) {
            _removeParticipants(_from, _to);
        }

        _transfer(address(this), _to, _amount);
        emit TransferApproved(_from, _to, _amount);
    }

    /**
     * @dev Rejects transfer of tokens
     * The rejectTransfer method is used for a withdraw workflow, allowing the owner of the contracts to approve
     * tokens on your behalf, for example to "deposit" to a contract address and/or to charge
     * fees in sub-currencies;
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     */
    function rejectTransfer(address _from, address _to)
        external
        notStopped
        onlyAdmin
    {
        require(transferBalances[_from][_to] > 0, ERROR_TRANSFER_NOT_FOUND);

        uint256 amount = transferBalances[_from][_to];
        transferBalances[_from][_to] = 0;
        _removeParticipants(_from, _to);

        _transfer(address(this), _from, amount);
        emit TransferRejected(_from, _to, amount);
    }

    /**
    * @notice Request force transfer from one account to the another
    * @param _from The address which you want to send tokens from
    * @param _to The address which you want to transfer to
    * @param _amount The amount of tokens to be transferred
    */
    function forceTransferRequest(address _from, address _to, uint256 _amount)
        public
        notStopped
        onlyRole(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN)
    {
        _validateTransfer(_from, _to, _amount);

        if (forceTransferApproval) {
            forceTransferInitiators[_from][_to][_amount] = msg.sender;
            emit ForceTransferRequested(_from, _to, _amount);
        } else {
            _forceTransfer(_from, _to, _amount);
        }
    }

    /**
     * @dev Force transfer from one account to the another without off-chain verification
     * @param _from The address which you want to send tokens from
     * @param _to The address which you want to transfer to
     * @param _amount The amount of tokens to be transferred
     */
    function forceTransfer(address _from, address _to, uint256 _amount)
        public
        notStopped
        onlyRoleStrict(ROLE_INVENIAM_ADMIN)
    {
        if (forceTransferApproval) {
            address initiator = forceTransferInitiators[_from][_to][_amount];
            require(initiator != address(0), ERROR_ACTION_WAS_NOT_REQUESTED);
            require(initiator != msg.sender, ERROR_ACTION_WAS_REQUESTED_BY_SENDER);
        }

        require(_amount <= balanceOf(_from), ERROR_AMOUNT_IS_NOT_AVAILABLE);
        _forceTransfer(_from, _to, _amount);

        if (forceTransferApproval) {
            delete forceTransferInitiators[_from][_to][_amount];
        }
    }

    function _forceTransfer(address _from, address _to, uint256 _amount) private {
        _transfer(_from, _to, _amount);
        emit ForcedTransfer(_from, _to, _amount);
        emit TransferApproved(msg.sender, _to, _amount);
    }

    /**
     * @dev Update amount of tokens to be supplied by contract
     * @param _newTotalSupply The new amount of tokens to be supplied
     */
    function changeTotalSupply(uint256 _newTotalSupply) public notStopped onlyRole(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN) {
        require(_newTotalSupply != totalSupply(), ERROR_INVALID_TOTAL_SUPPLY);

        bool isReducing = _newTotalSupply < totalSupply();
        uint256 delta;
        if (isReducing) {
            delta = totalSupply().sub(_newTotalSupply);
            _burn(owner(), delta);
        } else {
            delta = _newTotalSupply.sub(totalSupply());
            _mint(owner(), delta);
        }
        emit SupplyChanged(delta, totalSupply());
    }

    /**
    * @dev Attaches document to token
    * @param _data string Text message with metadata
    */
    function setDocument(string calldata _data) external notStopped onlyRole(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN) {
        if (address(documentManager) != address(0x00)) {
            IDocumentManager(documentManager).setDocument(symbol(), _data);
        } else {
            emit RawDocumentAdded(_data);
        }
    }

    /**
     * @dev Transfer token for a specified addresses and update balances history
     * @param _from The address to transfer from
     * @param _to The address to transfer to
     * @param _amount The amount to be transferred
     */
    function _transfer(address _from, address _to, uint256 _amount) internal {
        super._transfer(_from, _to, _amount);
        if (saveHoldersHistory && _amount > 0) {
            uint balanceFrom = balanceOf(_from);
            uint balanceTo = balanceOf(_to);

            InveniamTokenLib.afterTransfer(
                address(this),
                _from,
                _to,
                balanceFrom,
                balanceTo,
                holderData,
                holders,
                historyBalances,
                historyHolders
            );
        }
    }

    /**
     * @dev Mints an amount of the token, assigns it to an account and updates balance history
     * @param _account The account that will receive the created tokens
     * @param _amount The amount that will be created
     */
    function _mint(address _account, uint256 _amount) internal {
        super._mint(_account, _amount);
        if (saveHoldersHistory && _amount > 0) {
            uint balance = balanceOf(_account);

            InveniamTokenLib.afterMint(
                _account,
                balance,
                holderData,
                holders,
                historyBalances,
                historyHolders
            );
        }
    }

    /**
     * @dev Burns an amount of the token of a given account and updates balance history
     * @param _account The account whose tokens will be burnt
     * @param _amount The amount that will be burnt
     */
    function _burn(address _account, uint256 _amount) internal {
        super._burn(_account, _amount);
        if (saveHoldersHistory && _amount > 0) {
            uint balance = balanceOf(_account);

            InveniamTokenLib.afterBurn(
                _account,
                balance,
                holderData,
                holders,
                historyBalances,
                historyHolders
            );
        }
    }

    /**
     * @dev Validates transfer
     * @param _from The address to transfer from
     * @param _to The address to transfer to
     * @param _amount The amount to be transferred
     */
    function _validateTransfer(address _from, address _to, uint256 _amount) internal view {
        InveniamTokenLib.validateTransfer(_from, _to, _amount, balanceOf(_from));
    }

    /**
     * @dev Checks whether transfer is approved
     * @param _from The address to transfer from
     * @param _to The address to transfer to
     * @param _amount The amount to be transferred
     */
    function _isApproved(address _spender, address _from, address _to, uint256 _amount) internal returns (bool) {
        return (transferManager != address(0x00) &&
                ITransferManager(transferManager).isApproved(_spender, _from, _to, _amount));
    }

    /**
     * @dev Requests transfer
     * @param _from The address to transfer from
     * @param _to The address to transfer to
     * @param _amount The amount to be transferred
     */
    function _requestTransfer(address _from, address _to, uint256 _amount) internal {
        transferBalances[_from][_to] = transferBalances[_from][_to].add(_amount);
        if (savePendingBalances) {
            InveniamTokenLib.requestTransfer(
                _from,
                _to,
                _amount,
                senderData,
                senders,
                transferBalances,
                senderToReceiverData,
                senderToReceivers
            );
        }
        emit TransferRequested(_from, _to, _amount);
    }

    /**
     * @dev Removes accounts from pending transfer list
     * @param _from The address to transfer from
     * @param _to The address to transfer to
     */
    function _removeParticipants(address _from, address _to) internal {
        if (savePendingBalances) {
            InveniamTokenLib.removeParticipants(
                _from,
                _to,
                senderData,
                senders,
                senderToReceiverData,
                senderToReceivers
            );
        }
    }

    /**
    * @dev Returns an address of the 'allowable' implementation.
    */
    function _getImplementation() internal view returns (address) {
        return allowable;
    }

}

// File: contracts/interfaces/ITokenFactory.sol

pragma solidity ^0.5.12;

/**
* @title Factory for token deployment
*/
interface ITokenFactory {

    /**
    * @notice Deploys token
    * @param _symbol Token symbol
    * @param _name Token name
    * @param _decimals Token decimals
    * @param _totalSupply Token total supply
    * @param _tokenOwner Owner of the deployed token
    * @param _tokenRegistry Token Registry
    */
    function deployToken(
        string calldata _symbol,
        string calldata _name,
        uint8 _decimals,
        uint256 _totalSupply,
        address _tokenOwner,
        address _tokenRegistry,
        bool _saveHoldersHistory,
        address _allowable,
        address _getter
    )
        external
        returns (address);

}

// File: contracts/registry/TokenFactory.sol

pragma solidity ^0.5.12;



/**
* @title Factory for token deployment
*/
contract TokenFactory is ITokenFactory, Ownable {

    /**
    * @notice Deploys token
    * @param _symbol Token symbol
    * @param _name Token name
    * @param _decimals Token decimals
    * @param _totalSupply Token total supply
    * @param _tokenOwner Owner of the deployed token
    * @param _tokenRegistry Token Registry
    */
    function deployToken(
        string calldata _symbol,
        string calldata _name,
        uint8 _decimals,
        uint256 _totalSupply,
        address _tokenOwner,
        address _tokenRegistry,
        bool _saveHoldersHistory,
        address _allowable,
        address _getter
    )
        onlyOwner //owner - TokenRegistry
        external
        returns (address)
    {
        address tokenAddress = address(new InveniamToken(
            _symbol,
            _name,
            _decimals,
            _totalSupply * uint256(10)**_decimals,
            _tokenOwner,
            _tokenRegistry,
            _saveHoldersHistory,
            _allowable,
            _getter
        ));
        Allowable(tokenAddress).transferOwnership(_tokenOwner);
        return tokenAddress;
    }

}
