pragma solidity ^0.5.6;

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
     * @return A uint256 representing the amount owned by the passed address.
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
     * @dev Transfer token to a specified address
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
        _approve(msg.sender, spender, value);
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
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
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
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
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
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

contract IERC20Releasable {
    function release() public;
}

contract IOwnable {
    function isOwner(address who)
        public view returns(bool);

    function _isOwner(address)
        internal view returns(bool);
}

contract SingleOwner is IOwnable {
    address public owner;

    constructor(
        address _owner
    )
        internal
    {
        require(_owner != address(0), 'owner_req');
        owner = _owner;

        emit OwnershipTransferred(address(0), owner);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier ownerOnly() {
        require(msg.sender == owner, 'owner_access');
        _;
    }

    function _isOwner(address _sender)
        internal
        view
        returns(bool)
    {
        return owner == _sender;
    }

    function isOwner(address _sender)
        public
        view
        returns(bool)
    {
        return _isOwner(_sender);
    }

    function setOwner(address _owner)
        public
        ownerOnly
    {
        address prevOwner = owner;
        owner = _owner;

        emit OwnershipTransferred(owner, prevOwner);
    }
}

contract Privileged {
    /// List of privileged users who can transfer token before release
    mapping(address => bool) privileged;

    function isPrivileged(address _addr)
        public
        view
        returns(bool)
    {
        return privileged[_addr];
    }

    function _setPrivileged(address _addr)
        internal
    {
        require(_addr != address(0), 'addr_req');

        privileged[_addr] = true;
    }

    function _setUnprivileged(address _addr)
        internal
    {
        privileged[_addr] = false;
    }
}

contract IToken is IERC20, IERC20Releasable, IOwnable {}

contract MBN is IToken, ERC20, SingleOwner, Privileged {
    string public name = 'Membrana';
    string public symbol = 'MBN';
    uint8 public decimals = 18;
    bool public isReleased;
    uint public releaseDate;

    constructor(address _owner)
        public
        SingleOwner(_owner)
    {
        super._mint(owner, 1000000000 * 10 ** 18);
    }

    // Modifiers
    modifier releasedOnly() {
        require(isReleased, 'released_only');
        _;
    }

    modifier notReleasedOnly() {
        require(! isReleased, 'not_released_only');
        _;
    }

    modifier releasedOrPrivilegedOnly() {
        require(isReleased || isPrivileged(msg.sender), 'released_or_privileged_only');
        _;
    }

    // Methods

    function transfer(address to, uint256 value)
        public
        releasedOrPrivilegedOnly
        returns (bool)
    {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value)
        public
        releasedOnly
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value)
        public
        releasedOnly
        returns (bool)
    {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue)
        public
        releasedOnly
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue)
        public
        releasedOnly
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function release()
        public
        ownerOnly
        notReleasedOnly
    {
        isReleased = true;
        releaseDate = now;
    }

    function setPrivileged(address _addr)
        public
        ownerOnly
    {
        _setPrivileged(_addr);
    }

    function setUnprivileged(address _addr)
        public
        ownerOnly
    {
        _setUnprivileged(_addr);
    }
}

contract Ownable {
    address private _owner;

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract InvestorVesting is Ownable {
    using SafeMath for uint256;

    mapping (address => Holding) public holdings;

    struct Holding {
        uint256 tokensCommitted;
        uint256 tokensRemaining;
        uint256 startTime;
    }

    /**
     * Tokens vesting stage structure with vesting date and tokens allowed to unlock.
     */
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }

    /**
     * Array for storing all vesting stages with structure defined above.
     */
    VestingStage[6] public stages;

    event InvestorVestingInitialized(address _to, uint256 _tokens, uint256 _startTime);
    event InvestorVestingUpdated(address _to, uint256 _totalTokens, uint256 _startTime);

    constructor() public {
        initVestingStages();
    }

    function claimTokens(address beneficiary)
        external
        onlyOwner
        returns (uint256 tokensToClaim)
    {
        uint256 tokensRemaining = holdings[beneficiary].tokensRemaining;

        require(tokensRemaining > 0, "All tokens claimed");

        uint256 tokensUnlockedPercentage = getTokensUnlockedPercentage();

        if (tokensUnlockedPercentage >= 100) {
            tokensToClaim = tokensRemaining;
            delete holdings[beneficiary];
        } else {

            uint256 tokensNotToClaim = (holdings[beneficiary].tokensCommitted.mul(100 - tokensUnlockedPercentage)).div(100);
            tokensToClaim = tokensRemaining.sub(tokensNotToClaim);
            tokensRemaining = tokensNotToClaim;
            holdings[beneficiary].tokensRemaining = tokensRemaining;
        }

    }

    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime
    )
        external
        onlyOwner
    {

        if (holdings[_beneficiary].tokensCommitted != 0) {
            holdings[_beneficiary].tokensCommitted = holdings[_beneficiary].tokensCommitted.add(_tokens);
            holdings[_beneficiary].tokensRemaining = holdings[_beneficiary].tokensRemaining.add(_tokens);

            emit InvestorVestingUpdated(
                _beneficiary,
                holdings[_beneficiary].tokensRemaining,
                holdings[_beneficiary].startTime
            );

        } else {
            holdings[_beneficiary] = Holding(
                _tokens,
                _tokens,
                _startTime
            );

            emit InvestorVestingInitialized(_beneficiary, _tokens, _startTime);
        }
    }

    /**
     * Get tokens unlocked percentage on current stage.
     *
     * @return Percent of tokens allowed to be sent.
     */
    function getTokensUnlockedPercentage () private view returns (uint256) {
        uint256 allowedPercent;

        for (uint8 i = 0; i < stages.length; i++) {
            if (now >= stages[i].date) {
                allowedPercent = stages[i].tokensUnlockedPercentage;
            }
        }

        return allowedPercent;
    }

    /**
     * Setup array with vesting stages dates and percents.
     */
    function initVestingStages () internal {
        stages[0].date = 1563408000;
        stages[1].date = 1566086400;
        stages[2].date = 1568764800;
        stages[3].date = 1571356800;
        stages[4].date = 1574035200;
        stages[5].date = 1576627200;

        stages[0].tokensUnlockedPercentage = 39;
        stages[1].tokensUnlockedPercentage = 51;
        stages[2].tokensUnlockedPercentage = 63;
        stages[3].tokensUnlockedPercentage = 75;
        stages[4].tokensUnlockedPercentage = 87;
        stages[5].tokensUnlockedPercentage = 100;
    }
}

contract TeamAdvisorVesting is Ownable {
    using SafeMath for uint256;

    mapping (address => Holding) public holdings;

    struct Holding {
        uint256 tokensCommitted;
        uint256 tokensRemaining;
        uint256 startTime;
    }

    /**
     * Tokens vesting stage structure with vesting date and tokens allowed to unlock.
     */
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }

    /**
     * Array for storing all vesting stages with structure defined above.
     */
    VestingStage[6] public stages;

    event TeamAdvisorInitialized(address _to, uint256 _tokens, uint256 _startTime);
    event TeamAdvisorUpdated(address _to, uint256 _totalTokens, uint256 _startTime);

    constructor() public {
        initVestingStages();
    }

    function claimTokens(address beneficiary)
        external
        onlyOwner
        returns (uint256 tokensToClaim)
    {
        uint256 tokensRemaining = holdings[beneficiary].tokensRemaining;
        require(tokensRemaining > 0, "All tokens claimed");

        uint256 tokensUnlockedPercentage = getTokensUnlockedPercentage();

        if (tokensUnlockedPercentage >= 100) {

            tokensToClaim = tokensRemaining;
            delete holdings[beneficiary];

        } else {

            uint256 tokensNotToClaim = (holdings[beneficiary].tokensCommitted.mul(100 - tokensUnlockedPercentage)).div(100);

            tokensToClaim = tokensRemaining.sub(tokensNotToClaim);
            tokensRemaining = tokensNotToClaim;
            holdings[beneficiary].tokensRemaining = tokensRemaining;

        }
    }


    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime
    )
        external
        onlyOwner
    {

        if (holdings[_beneficiary].tokensCommitted != 0) {
            holdings[_beneficiary].tokensCommitted = holdings[_beneficiary].tokensCommitted.add(_tokens);
            holdings[_beneficiary].tokensRemaining = holdings[_beneficiary].tokensRemaining.add(_tokens);

            emit TeamAdvisorUpdated(
                _beneficiary,
                holdings[_beneficiary].tokensRemaining,
                holdings[_beneficiary].startTime
            );

        } else {
            holdings[_beneficiary] = Holding(
                _tokens,
                _tokens,
                _startTime
            );

            emit TeamAdvisorInitialized(_beneficiary, _tokens, _startTime);
        }
    }

    /**
     * Get tokens unlocked percentage on current stage.
     *
     * @return Percent of tokens allowed to be sent.
     */
    function getTokensUnlockedPercentage () private view returns (uint256) {
        uint256 allowedPercent;

        for (uint8 i = 0; i < stages.length; i++) {
            if (now >= stages[i].date) {
                allowedPercent = stages[i].tokensUnlockedPercentage;
            }
        }

        return allowedPercent;
    }

    /**
     * Setup array with vesting stages dates and percents.
     */
    function initVestingStages () internal {
        stages[0].date = 1576627200;
        stages[1].date = 1579305600;
        stages[2].date = 1581984000;
        stages[3].date = 1584489600;
        stages[4].date = 1587168000;
        stages[5].date = 1589760000;

        stages[0].tokensUnlockedPercentage = 17;
        stages[1].tokensUnlockedPercentage = 34;
        stages[2].tokensUnlockedPercentage = 51;
        stages[3].tokensUnlockedPercentage = 68;
        stages[4].tokensUnlockedPercentage = 84;
        stages[5].tokensUnlockedPercentage = 100;
    }
}

contract Vesting is Ownable {
    using SafeMath for uint256;

    enum VestingUser { Public, Investor, TeamAdvisor }

    MBN public mbnContract;
    InvestorVesting public investorVesting;
    TeamAdvisorVesting public teamAdvisorVesting;

    mapping (address => VestingUser) public userCategory;
    mapping (address => uint256) public tokensVested;

    uint256 public totalAllocated;
    uint private releaseDate;

    event TokensReleased(address _to, uint256 _tokensReleased, VestingUser user);

    constructor(address _token) public {
        require(_token != address(0), "Invalid address");
        mbnContract = MBN(_token);
        releaseDate = mbnContract.releaseDate();
        investorVesting = new InvestorVesting();
        teamAdvisorVesting = new TeamAdvisorVesting();
    }

    /**
     * Claims token for the owner.
     */
    function claimTokens() external {
        uint8 category = uint8(userCategory[msg.sender]);

        uint256 tokensToClaim;

        if (category == 1) {
            tokensToClaim = investorVesting.claimTokens(msg.sender);
        } else if (category == 2) {
            tokensToClaim = teamAdvisorVesting.claimTokens(msg.sender);
        } else {
            revert('incorrect category, maybe unknown user');
        }

        require(tokensToClaim > 0, "No tokens to claim");

        totalAllocated = totalAllocated.sub(tokensToClaim);
        require(mbnContract.transfer(msg.sender, tokensToClaim), 'Insufficient balance in vesting contract');
        emit TokensReleased(msg.sender, tokensToClaim, userCategory[msg.sender]);
    }

    /**
     * Call this function to initialize/allot tokens to respective address
     */
    function vestTokens(address[] calldata beneficiary, uint256[] calldata tokens, uint8[] calldata userType) external onlyOwner {
        require(beneficiary.length == tokens.length && tokens.length == userType.length, 'data mismatch');
        uint256 length = beneficiary.length;

        for(uint i = 0; i<length; i++) {
            require(beneficiary[i] != address(0), 'Invalid address');

            tokensVested[beneficiary[i]] = tokensVested[beneficiary[i]].add(tokens[i]);
            initializeVesting(beneficiary[i], tokens[i], releaseDate, Vesting.VestingUser(userType[i]));
        }
    }

    /**
     * Claim Unallocated tokens. Transfer tokens to address passed.
     */
    function claimUnallocated( address _sendTo) external onlyOwner{
        uint256 allTokens = mbnContract.balanceOf(address(this));
        uint256 tokensUnallocated = allTokens.sub(totalAllocated);
        mbnContract.transfer(_sendTo, tokensUnallocated);
    }

    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime,
        VestingUser user
    )
        internal
    {
        uint8 category = uint8(user);
        require(category != 0, 'Not eligible for vesting');
        require(uint8(userCategory[_beneficiary]) == 0 || userCategory[_beneficiary] == user, 'cannot change user category');

        userCategory[_beneficiary] = user;
        totalAllocated = totalAllocated.add(_tokens);

        if (category == 1) {
            investorVesting.initializeVesting(_beneficiary, _tokens, _startTime);
        } else if (category == 2) {
            teamAdvisorVesting.initializeVesting(_beneficiary, _tokens, _startTime);
        } else {
            revert('incorrect category, not eligible for vesting');
        }
    }

}
