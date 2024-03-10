// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Roles.sol

pragma solidity ^0.6.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/ownership/Ownable.sol

pragma solidity ^0.6.0;

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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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


// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;




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
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * - the caller must have allowance for `sender`'s tokens of at least
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

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
    function _mint(address account, uint256 amount) internal virtual {
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
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: browser/ContractorETH.sol

pragma solidity >0.6.1 <0.7.0;




contract Token is ERC20{}

/**
 * 
 * Master contract to handle all children team contracts
 * Author: Lastraum K.
 * Creation Date: 3.11.20
 * Version: 1.0
 * 
 */
contract MetaZoneMasterPaymentsContract is Ownable{
    using Roles for Roles.Role;
    Roles.Role private _adminmnz;
    
    mapping(address => address) public allTeams;
    mapping(address => address[]) public mateAllTeamAddresses;
    
    address[] public allTeamAddresses;
    
    uint256 platformFee = 0;
    uint256 public teamCount = 0;
    
    event NewTeam(address teamAddress, address[] teammates);
    
    constructor(address[] memory adminmnz)public{
        for (uint256 i = 0; i < adminmnz.length; ++i) {
            _adminmnz.add(adminmnz[i]);
        }
    }
    
    /**
     *
     * Create a new child team with a team name, specific teammates, and their percentage splits
     * 
     */
    function newTeam(string memory name, address[] memory newmembers, uint256[] memory splits)public returns(address){
        
        Team team = new Team(name, newmembers, splits, platformFee);
        allTeamAddresses.push(address(team));
        allTeams[address(team)] = address(team);
        
        for(uint i = 0; i < newmembers.length; i++){
            mateAllTeamAddresses[newmembers[i]].push(address(team));
        }
        teamCount = teamCount + 1;
        
        emit NewTeam(address(team), newmembers);
        return address(team);
    }

    /**
     *
     * Return all child team addresses for a given address
     * 
     */
    function getAllTeamAddressesForMate(address mate)public view returns(address[] memory){
        return mateAllTeamAddresses[mate];
    }
    
    /**
     *
     * Withdraw supplied token parameter from all teams that correspond to the caller
     * 
     */
    function withdrawAllTokenForMate(string memory tokenSymbol)public{
        require(mateAllTeamAddresses[msg.sender].length > 0, "Sender is not a part of any teams");
        address[] memory mateTeams = mateAllTeamAddresses[msg.sender];
        for(uint i = 0; i < mateTeams.length; i++){
            Team team = Team(payable(mateTeams[i]));
            if(team.getMateAmount(msg.sender,tokenSymbol) > 0){
               team.specificMateWithdrawSpecificToken(msg.sender, tokenSymbol); 
            }
        }
    }
    
    /**
     *
     * Return all team addresses stored in the master contract
     * 
     */
    function getAllTeamAddresses()public view returns(address[] memory teamAddresses){
        return allTeamAddresses;
    }
    
    /**
     *
     * Admin fail safe function to withdraw a supplied token parameter from a given team address to manually transfer to teammates
     * 
     */
    function salvageTokenFromTeam(address teamAddress, string memory tokenSymbol)public{
        require(_adminmnz.has(msg.sender), "Does not have admin role");
        require(allTeams[teamAddress] != address(0), "Team address does not exist.");
        
        Team team = Team(payable(allTeams[teamAddress]));
        team.adminWithdrawalOfToken(msg.sender, tokenSymbol);
    }
    
}

    /**
     *
     * A specific team contract made up of mates and their percentage split of the transfers into the team contract
     * 
     */
contract Team is Ownable{
using SafeMath for uint256;

    struct AcceptedToken{
        string symbol;
        address tokenAddress;
    }
    
    AcceptedToken[] public acceptedTokens;
    
    mapping (address => Teammate) mates;
    mapping (uint => address) mateIndex;
    address[] matesAddresses;
    
    struct Teammate{
        address userID;
        uint256 percentage;
        uint256[] amounts;
        bool accepted;
    }
    
    bool allocating = false;
    bool distributing = false;
    
    mapping (string => AcceptedToken) acceptedTokenBySymbol;
    mapping (address => address) acceptedTokenAddresses;
    mapping (string => uint) acceptedTokenGetIndexBySymbol;
    
    uint256 public memberCount;
    
    uint256[] public allocatedAmounts;
    
    string public nextPayout;
    string public teamName;
    
    event AllocatedAmounts(uint256 amount, string tokenSymbol);
    
    //TODO
    //add/remove mates
    //voting and verification system
    constructor(string memory name, address[] memory newmembers, uint256[] memory splits, uint256 platformFee) public {
        
        teamName = name;
        
        uint256 percentageCheck;
        for(uint i =0; i < newmembers.length; i++)
        {
            mates[newmembers[i]].userID = newmembers[i];
            if(newmembers[i] == msg.sender)
            {
                mates[newmembers[i]].accepted = true;
            }
            else
            {
                mates[newmembers[i]].accepted = false;
            }
            
            ///add a check if the platform fee is zero to not add the platform contract
            mates[newmembers[i]].percentage = splits[i];
            mateIndex[i] = newmembers[i];
            percentageCheck = percentageCheck + splits[i];
            matesAddresses.push(newmembers[i]);
            memberCount = memberCount + 1;
        }
        
        mates[address(msg.sender)].userID = address(msg.sender);
        mates[address(msg.sender)].accepted = false;
        mates[address(msg.sender)].percentage = platformFee;
        matesAddresses.push(msg.sender);
        mateIndex[memberCount] = address(msg.sender);
        
        memberCount = memberCount + 1;
        
        require(percentageCheck <= 100, "percentages are over 100%");
        
        percentageCheck = percentageCheck + platformFee;
        if(percentageCheck < 100)
        {
            mates[address(msg.sender)].percentage = mates[address(msg.sender)].percentage + (100 - percentageCheck);
        }
        
        _addAcceptedToken(address(0),"ETH");
        _addAcceptedToken(address(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942),"MANA");
    }
    
    /**
     *
     * Returns an amount allocated of a supplied token parameter for a given mate address
     * 
     */
    function getMateAmount(address mate, string memory _tokenSymbol) public view returns (uint256){
        return(mates[mate].amounts[acceptedTokenGetIndexBySymbol[_tokenSymbol]]);
    }
    
    
    /**
     *
     * Returns a mate array for the spplied address parameter
     * 
     */
    function getMateByAddress(address mate) public view returns (address,uint256,bool,uint256[] memory){
        return(
            mates[mate].userID,
            mates[mate].percentage,
            mates[mate].accepted,
            mates[mate].amounts);
    }
    
    /**
     *
     * Return the total team allocated amount for a supplied token parameter
     * 
     */
    function getAllocationForSymbol(string memory tokenSymbol) public view returns (uint256){
        return allocatedAmounts[acceptedTokenGetIndexBySymbol[tokenSymbol]];
    }
    
    /**
     *
     * Update the team contract to manage and allocate the newly supplied ERC20 token
     * 
     */
    function addAcceptedToken(address t, string memory s) public onlyOwner{
        _addAcceptedToken(t,s);
    }
    
    /**
     *
     * internal function for the above token addition
     * 
     */
    function _addAcceptedToken(address t, string memory s) internal {
        AcceptedToken memory token = AcceptedToken({
            symbol: s,
            tokenAddress: t
        });
        acceptedTokens.push(token);
        acceptedTokenAddresses[t] = t;
        acceptedTokenGetIndexBySymbol[s] = acceptedTokens.length-1;
        allocatedAmounts.push(0);
        acceptedTokenBySymbol[s] = token;
        for(uint i = 0; i < memberCount; i++)
        {
            mates[mateIndex[i]].amounts.push(0);
        }
    }
    
    /** add a sync method if tokens get sent but the contract doesn't have them stored in the arrays
     * might need to be manual to check which tokens were received and then add that token to array and
     * loop through members to allocate the balance
     */
    
    /**
     *
     * function to allocation a supplied token parameter to all mates of the team contract
     * 
     */
    function allocateTokenToMates(string memory tokenSymbol) public{
        //require(!allocating);
        //allocating = true;
        
        if((keccak256(abi.encodePacked(tokenSymbol)) == (keccak256(abi.encodePacked("ETH")))))
        {
            _allocateETH();
        }
        else
        {
            //require(msg.sender == mates[msg.sender].userID, "sender is not a part of this team");
            require((keccak256(abi.encodePacked(tokenSymbol)) == keccak256(abi.encodePacked(acceptedTokenBySymbol[tokenSymbol].symbol))));

            bool assignable = false;
            
            Token token = Token(address(acceptedTokenBySymbol[tokenSymbol].tokenAddress));
            
            uint256 contractBalance = token.balanceOf(address(this));
            uint acceptedTokenIndex = acceptedTokenGetIndexBySymbol[tokenSymbol];
            uint256 contractAllocationAmount = allocatedAmounts[acceptedTokenIndex];
            
            if(contractAllocationAmount != contractBalance)
            {
                allocatedAmounts[acceptedTokenIndex] = contractBalance - contractAllocationAmount;
                assignable = true;
            }
            
            if(assignable)
            {
                for(uint256 i = 0; i < memberCount;i++){
                uint256 allocatedAmount = allocatedAmounts[acceptedTokenIndex];
                uint256 percentage = mates[matesAddresses[i]].percentage;
                mates[matesAddresses[i]].amounts[acceptedTokenIndex] =  mates[matesAddresses[i]].amounts[acceptedTokenIndex]  + (allocatedAmount * percentage /100);
                }   
                allocatedAmounts[acceptedTokenIndex] = contractBalance;
                
                emit AllocatedAmounts(allocatedAmounts[acceptedTokenIndex], tokenSymbol);
            }
            
        }    
        //allocating = false;
    }
    
    /**
     *
     * allow this contract to receive ETH
     * 
     */
    receive() external payable{
        _allocateETH();
    }    
    
    /**
     *
     * internal function for the above ETH receipt
     * 
     */
    function _allocateETH() internal {
        //require(!allocating);
        //allocating = true;
        bool assignETH = false;
        
        uint256 balance = address(this).balance;
        
        if(allocatedAmounts[0] != balance)
        {
            allocatedAmounts[0] = balance - allocatedAmounts[0];
            assignETH = true;
        }
        
        if(assignETH)
        {
            for(uint256 i = 0; i < memberCount;i++){
            uint256 percentage = mates[matesAddresses[i]].percentage;
            uint256 mateCurrentAmount = mates[matesAddresses[i]].amounts[0];
            mates[matesAddresses[i]].amounts[0] = mateCurrentAmount + (allocatedAmounts[0] * percentage /100);
            }   
        }        
    }
    
    /**
     *
     * Return the total balance of a supplied token parameter for the entire team contract
     * 
     */
    function getBalanceOfTokenBySymbol(string memory symbol) public view returns (uint256) {
        require((keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked(acceptedTokenBySymbol[symbol].symbol))), "token is not accepted for this contract");
        if((keccak256(abi.encodePacked(symbol)) == (keccak256(abi.encodePacked("ETH")))))
        {
            return address(this).balance;
        }
        else
        {
            return Token(address(acceptedTokenBySymbol[symbol].tokenAddress)).balanceOf(address(this));
        }
    }
    
    /**
     *
     * Function to extract all eth from the team contract and set each mate's allocation to 0. This is used by admins for manual fallback payments
     * 
     */
    function adminWithdrawalOfToken(address admin, string memory tokenSymbol) public onlyOwner {
        if((keccak256(abi.encodePacked(tokenSymbol)) == (keccak256(abi.encodePacked("ETH")))))
        {
            _adminWithdrawalETH(admin);
        }
        else
        {
            require((keccak256(abi.encodePacked(tokenSymbol)) == keccak256(abi.encodePacked(acceptedTokenBySymbol[tokenSymbol].symbol))));

            Token token = Token(address(acceptedTokenBySymbol[tokenSymbol].tokenAddress));
            
            allocatedAmounts[acceptedTokenGetIndexBySymbol[tokenSymbol]] = 0;
            for(uint i = 0; i < memberCount; i++)
            {
                mates[mateIndex[i]].amounts[acceptedTokenGetIndexBySymbol[tokenSymbol]] = 0;
            }
            
            uint256 disbursement = token.balanceOf(address(this));
            token.transfer(admin,disbursement);
        }  
    }
    
    /**
     *
     * internal function for the above admin withdrawal of ETH
     * 
     */
    function _adminWithdrawalETH(address admin) internal returns(address) {
        uint256 currentBalance = (address(this).balance);
        address payable paymember = payable(admin);
        paymember.transfer(currentBalance);
    }
    
    /**
     *
     * Function called from the master contract to distrube and transfer a supplied token parameter to all mates for this team contract
     * 
     */
    function distributeSpecificToken(string memory tokenSymbol) public onlyOwner{
        for(uint i = 0; i < memberCount; i++)
        {
            //check if they have accepted or not
            _distributeSpecificToken(mateIndex[i], tokenSymbol);
        }
    }
    
    /**
     *
     * internal function to distribute and transfer of all supplied token parameter
     * 
     */
    function _distributeSpecificToken(address mate, string memory tokenSymbol) internal{
        //require(!distributing);
        //require(!allocating);
        //distributing = true;
        if((keccak256(abi.encodePacked(tokenSymbol)) == (keccak256(abi.encodePacked("ETH")))))
        {
            _distributeETH(mate);
        }
        else
        {
            require((keccak256(abi.encodePacked(tokenSymbol)) == keccak256(abi.encodePacked(acceptedTokenBySymbol[tokenSymbol].symbol))));

            uint256 disbursement = mates[mate].amounts[acceptedTokenGetIndexBySymbol[tokenSymbol]];
            mates[mate].amounts[acceptedTokenGetIndexBySymbol[tokenSymbol]] = 0;    
            
            Token token = Token(address(acceptedTokenBySymbol[tokenSymbol].tokenAddress));
            token.transfer(mate,disbursement);
            allocatedAmounts[acceptedTokenGetIndexBySymbol[tokenSymbol]] = allocatedAmounts[acceptedTokenGetIndexBySymbol[tokenSymbol]] - disbursement;
        }       
        //distributing = false;
    }
    
    /**
     *
     * internal function to distribute and transfer of all eth to the supplied mate address
     * 
     */
    function _distributeETH(address mate)internal{
        address payable paymember = payable(mate);
        paymember.transfer(mates[mate].amounts[0]);
        mates[mate].amounts[0] = 0;            
    }
    
    /**
     *
     * Function called by master contract to withdraw a supplied token from the team contract to a supplied mate address
     * 
     */
    function specificMateWithdrawSpecificToken(address mate, string memory ttokenSymbol)public onlyOwner{
        ///require the sender to be the owner of this contract aka the global contract
        _distributeSpecificToken(mate, ttokenSymbol);
        
    }

}
