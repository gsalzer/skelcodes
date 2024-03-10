/**
 *Submitted for verification at Etherscan.io on 2020-08-22
*/

pragma solidity ^0.5.14;

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

// File: node_modules\@openzeppelin\contracts\ownership\Ownable.sol


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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() public {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

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


contract WIPcoin is ERC20, ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using Roles for Roles.Role;

    Roles.Role private _admin;

    event MintWIP(address mintingAddress, uint256 amount);
    event BurnWIP(uint256 amount);

    mapping (address => uint256) private amountClaimableByAddress;

    uint8 constant public decimals = 18;
    string constant public name = "WIPcoin";
    string constant public symbol = "WIPC";
    uint256 constant public WIPHardCap = 1000000;
    uint256 public timerInitiated;
    uint256 public halvingIndex;
    uint256 public halvingTimeStamp;
    uint256 constant public halvingPeriodSeconds = 19353600;
    bool public numberOfAttendeesSet;
    bool public weeklyCountFinalized;
    bool public backDropComplete;
    
    address public expensesWeeklyAddress;
    address public promoWeeklyAddress;

    uint256 claimTimeDelay;
    uint256 thisWeeksAttendees;
    uint256 totalMeetups;
    uint256 totalAttendees;
    
    uint256 expensesSplit;
    uint256 promotionalSplit;
    uint256 communitySplit;
    
    constructor() public {
        _mint(0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3, WIPHardCap*6*10**16);
        _mint(0x442DCCEe68425828C106A3662014B4F131e3BD9b, WIPHardCap*6*10**16);
        _mint(0x81E5cd19323ce7f6b36c9511fbC98d477a188b13, WIPHardCap*6*10**16);
        _mint(0xc2F82A1F287B5b5AEBff7C19e83e0a16Cf3bD041, WIPHardCap*6*10**16);
        _mint(0xfd3be6f4D3E099eDa7158dB21d459794B25309F8, WIPHardCap*6*10**16);
        timerInitiated = block.timestamp;
        halvingTimeStamp = timerInitiated + halvingPeriodSeconds;
        halvingIndex = 0;
        totalMeetups = 22;
        totalAttendees = 1247;
        backDropComplete = false;
        expensesWeeklyAddress = 0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3;
        promoWeeklyAddress = 0x1082ACF0F6C0728F80FAe05741e6EcDEF976C181;
        communitySplit = 60;
        expensesSplit = 25;
        promotionalSplit = 15;
        _admin.add(0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3);
        _admin.add(0x442DCCEe68425828C106A3662014B4F131e3BD9b);
        _admin.add(0x81E5cd19323ce7f6b36c9511fbC98d477a188b13);
        _admin.add(0xc2F82A1F287B5b5AEBff7C19e83e0a16Cf3bD041);
    }

    function getWeeklyDistribution() public view returns (uint256 communityDistributionAmount, uint256 expensesDistributionAmount, uint256 promotionalDistributionAmount) {
        uint256 halvingDecay = 2**halvingIndex;
        uint256 totalDistributionAmount = WIPHardCap*1/halvingDecay*10**16;
        
        communityDistributionAmount = totalDistributionAmount*communitySplit/100;
        expensesDistributionAmount = totalDistributionAmount*expensesSplit/100;
        promotionalDistributionAmount = totalDistributionAmount*promotionalSplit/100;
    }

    function getCirculatingWIP() private view returns (uint256 circulatingWIP) {
        circulatingWIP = totalSupply().div(10**18); 
    }

    function updateHalvingIndex() private {
        if (getTimeToNextHalving() <= 0) {
            halvingIndex = halvingIndex + 1;
        }
        halvingTimeStamp = timerInitiated + ((halvingIndex + 1) * halvingPeriodSeconds);
    }

    function getTimeToNextHalving() private view returns (int256 timeToNextHalving){
        timeToNextHalving = int256(halvingTimeStamp - block.timestamp);
    }

    function updateNumberOfAttendees(uint256 numberOfAttendees) public {
        require(_admin.has(msg.sender), "Only official admin can update number of attendees.");
        require (getTimeToDelayEnd() <= 0);
        
        numberOfAttendeesSet = true;
        weeklyCountFinalized = false;
        thisWeeksAttendees = numberOfAttendees; 
        
        updateHalvingIndex();
    }

    function pushAddresses(address[] memory attendee) public nonReentrant {
        require(_admin.has(msg.sender), "Only official admin can push attendee addresses.");
        require(getTimeToNextHalving() >= 0);
        require(getTimeToNextHalving() <= int256(halvingPeriodSeconds));
        
        require(numberOfAttendeesSet == true);
        require(thisWeeksAttendees == attendee.length);
        
        uint256 crowdDistribution;
        (crowdDistribution,,) = getWeeklyDistribution();
        
        uint256 weeklyWIPDistribution = crowdDistribution/thisWeeksAttendees;
        for(uint256 i = 0; i < attendee.length; i++){
            amountClaimableByAddress[attendee[i]] = amountClaimableByAddress[attendee[i]] + weeklyWIPDistribution;
        }
        
        finalizeWeeklyAddresses();
    }
    
    function initialBackDrop(address[] memory attendee, uint256[] memory backDropAmount) public onlyOwner nonReentrant {
        require(backDropComplete == false);
        require(attendee.length == backDropAmount.length);
        
        for(uint256 i = 0; i < attendee.length; i++){
            amountClaimableByAddress[attendee[i]] = amountClaimableByAddress[attendee[i]] + backDropAmount[i];
        }
        
        backDropComplete = true;
    }

    function finalizeWeeklyAddresses() private {
        numberOfAttendeesSet = false;
        weeklyCountFinalized = true;
        totalMeetups = totalMeetups + 1;
        totalAttendees = totalAttendees + thisWeeksAttendees;
        claimTimeDelay = block.timestamp + 518400; //6 days to allow for some input lag
        claimTeamWeekly();
    }
    
    function getTimeToDelayEnd() private view returns (int256 timeToDelayEnd){
        timeToDelayEnd = int256(claimTimeDelay - block.timestamp);
    }

    function claimWIPCoin() public nonReentrant {
        require(weeklyCountFinalized == true);
        uint256 amountToClaim = amountClaimableByAddress[msg.sender];
        amountClaimableByAddress[msg.sender] = 0;
        
        require(getCirculatingWIP() + amountToClaim <= WIPHardCap.mul(10**18));
        
        _mint(msg.sender, amountToClaim);
        emit MintWIP(msg.sender, amountToClaim.div(10**18));
    }
    
    function claimTeamWeekly() private {
        require(weeklyCountFinalized == true);
        
        uint256 expensesDistribution;
        uint256 promotionalDistribution;
        (,expensesDistribution, promotionalDistribution) = getWeeklyDistribution();
        
        require(getCirculatingWIP() + expensesDistribution <= WIPHardCap.mul(10**18));
        _mint(expensesWeeklyAddress, expensesDistribution);
        emit MintWIP(expensesWeeklyAddress, expensesDistribution.div(10**18));
        
        require(getCirculatingWIP() + promotionalDistribution <= WIPHardCap.mul(10**18));
        _mint(promoWeeklyAddress, promotionalDistribution);
        emit MintWIP(promoWeeklyAddress, promotionalDistribution.div(10**18));        
    }
    
    function updateTeamWeekly(address newTeamWeekly) public onlyOwner {
        expensesWeeklyAddress = newTeamWeekly;
    }

    function updatePromoWeekly(address newPromoWeekly) public onlyOwner {
        promoWeeklyAddress = newPromoWeekly;
    }
    
    function adjustWeeklySplit(uint256 newExpenses, uint256 newPromo, uint256 newCommunity) public onlyOwner {
        require(newExpenses + newPromo + newCommunity == 100);
        
        expensesSplit = newExpenses;
        promotionalSplit = newPromo;
        communitySplit = newCommunity;
    }
    
    function getStats() public view returns (uint256 meetups, uint256 attendees, uint256 weeklyAttendees , uint256 circulatingSupply, int256 nextHalvingCountdown, int256 nextTimeDelayEnding, uint256 expensesPercent, uint256 promotionalPercent, uint256 communityPercent){
        meetups = totalMeetups;
        attendees =  totalAttendees;
        weeklyAttendees = thisWeeksAttendees;
        circulatingSupply = getCirculatingWIP();
        nextHalvingCountdown = getTimeToNextHalving();
        nextTimeDelayEnding = getTimeToDelayEnd();
        expensesPercent = expensesSplit;
        promotionalPercent = promotionalSplit;
        communityPercent = communitySplit;
    }
    
    function getAmountClaimable(address userAddress) public view returns (uint256 amountClaimable) {
        amountClaimable = amountClaimableByAddress[userAddress];
    }
    
    function addAdminAddress(address newAdminAddress) public onlyOwner {
        _admin.add(newAdminAddress);
    }
    
    function removeAdminAddress(address oldAdminAddress) public onlyOwner {
        _admin.remove(oldAdminAddress);
    }
    
    function burnWIP(uint256 WIPToBurn) public nonReentrant {
        _burn(msg.sender, WIPToBurn);
        emit BurnWIP(WIPToBurn.div(10**18));
        }
    }
