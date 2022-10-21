pragma solidity >=0.4.22 <0.8.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
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

pragma solidity >=0.4.22 <0.8.0;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


pragma solidity >=0.4.22 <0.8.0;

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
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


pragma solidity >=0.4.22 <0.8.0;

/**
 * @title FarmOrDie interface
 */
interface IFarmOrDie {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity >=0.4.22 <0.8.0;


contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity >=0.4.22 <0.8.0;

contract FarmOrDie is Ownable, IFarmOrDie {

    using SafeMath for uint256;

    event LogBurn(uint256 indexed epoch, uint256 totalSupply);

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public constant name = "Farm Or Die";
    string public constant symbol = "SKULLS";
    uint256 public constant decimals = 18;

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0); //(2^256) - 1
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 26000 * 10**DECIMALS;

    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = ~uint128(0); //(2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping (address => mapping (address => uint256)) private _allowedFragments;

    function burn(uint256 epoch, uint256 decayrate) external onlyOwner returns (uint256)
    {
        uint256 _remainrate = 100;
        _remainrate = _remainrate.sub(decayrate);


        _totalSupply = _totalSupply.mul(_remainrate);
        _totalSupply = _totalSupply.sub(_totalSupply.mod(100));
        _totalSupply = _totalSupply.div(100);

        
        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        emit LogBurn(epoch, _totalSupply);
        return _totalSupply;
    }

    constructor() public {
        _owner = msg.sender;
        
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[_owner] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        emit Transfer(address(0x0), _owner, _totalSupply);
    }

    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address who) public view returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function transfer(address to, uint256 value) public  validRecipient(to) returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner_, address spender) public view returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function transferFrom(address from, address to, uint256 value) public validRecipient(to) returns (bool)
    {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function mint(address account, uint256 value) public {
        require(account != address(0));

        uint256 gonValue = value.mul(_gonsPerFragment);

        _totalSupply = _totalSupply.add(gonValue);   
        _gonBalances[account] = _gonBalances[account].add(gonValue);
        emit Transfer(address(0), account, value);
    }
}


pragma solidity >=0.4.22 <0.8.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
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


pragma solidity >=0.4.22 <0.8.0;

/**
 * @title FarmOrDieMintable
 * @dev FarmOrDie minting logic.
 */
contract FarmOrDieMintable is FarmOrDie, MinterRole {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function _mint(address to, uint256 value) public onlyMinter returns (bool) {
        mint(to, value);
        return true;
    }
}


pragma solidity >=0.4.22 <0.8.0;

contract Rewards is FarmOrDie, FarmOrDieMintable {

    using SafeMath for uint256;

    uint256 public roundMask;
    uint256 public lastMintedBlockNumber;
    uint256 public totalParticipants = 0;
    uint256 public tokensPerBlock; 
    uint256 public blockFreezeInterval; 
    address public tokencontractAddress = address(this);
    mapping(address => uint256) public participantMask; 

    
    constructor(uint256 _tokensPerBlock, uint256 _blockFreezeInterval) public FarmOrDieMintable(){ 
        lastMintedBlockNumber = block.number;
        tokensPerBlock = _tokensPerBlock;
        blockFreezeInterval = _blockFreezeInterval;
    }

    /**
     * @dev Modifier to check if msg.sender is whitelisted as a minter. 
     */
    modifier isAuthorized() {
        require(isMinter(msg.sender));
        _;
    }

    /**
     * @dev Function to add participants in the network. 
     * @param _minter The address that will be able to mint tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function addMinters(address _minter) external returns (bool) {
    _addMinter(_minter);
        totalParticipants = totalParticipants.add(1);
        updateParticipantMask(_minter);
        return true;
    }

    /**
     * @dev Function to remove participants in the network. 
     * @param _minter The address that will be unable to mint tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function removeMinters(address _minter) external returns (bool) {
        totalParticipants = totalParticipants.sub(1);
        _removeMinter(_minter); 
        return true;
    }

    /**
     * @dev Function to introduce new tokens in the network. 
     * @return A boolean that indicates if the operation was successful.
     */
    function trigger() external isAuthorized returns (bool) {
        bool res = readyToMint();
        if(res == false) {
            return false;
        } else {
            mintTokens();
            return true;
        }
    }

    /**
     * @dev Function to withdraw rewarded tokens by a participant. 
     * @return A boolean that indicates if the operation was successful.
     */
    function withdraw() external isAuthorized returns (bool) {
        uint256 amount = calculateRewards();
        require(amount >0);
        FarmOrDie(tokencontractAddress).transfer(msg.sender, amount);
    }

    /**
     * @dev Function to check if new tokens are ready to be minted. 
     * @return A boolean that indicates if the operation was successful.
     */
    function readyToMint() public view returns (bool) {
        uint256 currentBlockNumber = block.number;
        uint256 lastBlockNumber = lastMintedBlockNumber;
        if(currentBlockNumber > lastBlockNumber + blockFreezeInterval) { 
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Function to calculate current rewards for a participant. 
     * @return A uint that returns the calculated rewards amount.
     */
    function calculateRewards() private returns (uint256) {
        uint256 playerMask = participantMask[msg.sender];
        uint256 rewards = roundMask.sub(playerMask);
        updateParticipantMask(msg.sender);
        return rewards;
    }

    /**
     * @dev Function to mint new tokens into the economy. 
     * @return A boolean that indicates if the operation was successful.
     */
    function mintTokens() private returns (bool) {
        uint256 currentBlockNumber = block.number;
        uint256 tokenReleaseAmount = (currentBlockNumber.sub(lastMintedBlockNumber)).mul(tokensPerBlock);
        lastMintedBlockNumber = currentBlockNumber;
        mint(tokencontractAddress, tokenReleaseAmount);
        calculateTPP(tokenReleaseAmount);
        return true;
    }

     /**
    * @dev Function to calculate TPP (token amount per participant).
    * @return A boolean that indicates if the operation was successful.
    */
    function calculateTPP(uint256 tokens) private returns (bool) {
        uint256 tpp = tokens.div(totalParticipants);
        updateRoundMask(tpp);
        return true;
    }

     /**
    * @dev Function to update round mask. 
    * @return A boolean that indicates if the operation was successful.
    */
    function updateRoundMask(uint256 tpp) private returns (bool) {
        roundMask = roundMask.add(tpp);
        return true;
    }

     /**
    * @dev Function to update participant mask (store the previous round mask)
    * @return A boolean that indicates if the operation was successful.
    */
    function updateParticipantMask(address participant) private returns (bool) {
        uint256 previousRoundMask = roundMask;
        participantMask[participant] = previousRoundMask;
        return true;
    }

}

pragma solidity >=0.4.22 <0.8.0;


/**
 * @title SafeFarmOrDie
 * @dev Wrappers around FarmOrDie operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeFarmOrDie for FarmOrDie;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeFarmOrDie {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IFarmOrDie token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IFarmOrDie token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IFarmOrDie token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IFarmOrDie token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IFarmOrDie token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IFarmOrDie token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.

        require(address(token).isContract());

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)));
        }
    }
}


pragma solidity >=0.4.22 <0.8.0;


/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeFarmOrDie for IFarmOrDie;

    IFarmOrDie private _token;

    address private _beneficiary;

    uint256 private _releaseTime;

    constructor (IFarmOrDie token, address beneficiary, uint256 releaseTime) public {
        require(releaseTime > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = releaseTime;
    }

    function token() public view returns (IFarmOrDie) {
        return _token;
    }

    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    function release() public {
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _token.safeTransfer(_beneficiary, amount);
    }
}

