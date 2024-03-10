pragma solidity 0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

contract BounceFinanceTest is Ownable {
    using SafeMath for uint256;

    modifier validRecipient(address account) {
        require(account != address(0x0));
        require(account != address(this));
        _;
    }

    struct Breeder {
        uint256 snapshotPeriod;
        uint256 snapshotBalance;
    }

    // events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LogWhitelisted(address indexed addr);
    event LogUnlocked(uint256 timestamp);
    event LogBandits(uint256 totalSupply);
    event LogBreed(uint256 indexed period, uint256 candidatesLength, uint256 estimatedBreeders, uint256 breededToken, uint256 availableUnits);

    // public constants
    string public constant name = "BounceFinance Test Token";
    string public constant symbol = "BFT";
    uint256 public constant decimals = 9;

    // private constants
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_TOKENS = 21 * 10**6;
    uint256 private constant INITIAL_SUPPLY = INITIAL_TOKENS * 10**decimals;
    uint256 private constant TOTAL_UNITS = MAX_UINT256 - (MAX_UINT256 % INITIAL_SUPPLY);
    uint256 private constant POOL_SIZE = 50; // 50%
    uint256 private constant INIT_POOL_FACTOR = 60;
    uint256 private constant BREED_MIN_BALANCE = 100 * 10**decimals;
    uint256 private constant BREED_ADDRESS_LIMIT = 1000;
    uint256 private constant TIMELOCK_TIME = 24 hours;
    uint256 private constant HALVING_PERIOD = 30;

    // mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private _whitelist;
    mapping(address => Breeder) private _breeders;
    mapping(address => bool) private _knownAddresses;
    mapping(uint256 => address) private _addresses;
    uint256 _addressesLength;

    // ints
    uint256 private _totalSupply;
    uint256 private _unitsPerToken;
    uint256 private _initialPoolToken;
    uint256 private _poolBalance;
    uint256 private _poolFactor;

    uint256 private _period;
    uint256 private _timelockBreeding;
    uint256 private _timelockBandits;

    // bools
    bool private _lockTransfer;
    bool private _lockBreeding;


    constructor() public override {
        _owner = msg.sender;

        // set toal supply = initial supply
        _totalSupply = INITIAL_SUPPLY;
        // set units per token based on total supply
        _unitsPerToken = TOTAL_UNITS.div(_totalSupply);

        // set pool balance = TOTAL_UNITS / 100 * POOL_SIZE
        _poolBalance = TOTAL_UNITS / 100 * POOL_SIZE;
        // set initial pool token balance
        _initialPoolToken = _poolBalance.div(_unitsPerToken);
        // set initial pool factor
        _poolFactor = INIT_POOL_FACTOR;

        // set owner balance
        _balances[_owner] = TOTAL_UNITS - _poolBalance;

        // init locks & set defaults
        _lockTransfer = true;
        _lockBreeding = true;

        emit Transfer(address(0x0), _owner, _totalSupply.sub(_initialPoolToken));
    }


    function whitelistAdd(address addr) external onlyOwner {
        _whitelist[addr] = true;
        emit LogWhitelisted(addr);
    }

    // main unlock function
    // 1. set period
    // 2. set timelocks
    // 3. allow token transfer
    function unlock() external onlyOwner {
        require(_period == 0, "contract is unlocked");
        _period = 1;
        _timelockBreeding = now.add(TIMELOCK_TIME);
        _timelockBandits = now.add(TIMELOCK_TIME);
        _lockTransfer = false;
        _lockBreeding = false;
        emit LogUnlocked(block.timestamp);
    }

    function getSnapshotBalance(address addr) private view returns (uint256) {
        if (_breeders[addr].snapshotPeriod < _period) {
            return _balances[addr];
        }
        return  _breeders[addr].snapshotBalance;
    }

    function calcShareInTokens(uint256 snapshotToken, uint256 totalBreedersToken, uint256 availableToken) private pure returns(uint256) {
        return availableToken.mul(snapshotToken).div(totalBreedersToken);
    }

    function isOwnerOrWhitelisted(address addr) private view returns (bool) {
        if (addr == _owner) {
            return true;
        }
        return _whitelist[addr];
    }

    function acquaintAddress(address candidate) private returns (bool) {
        if((_knownAddresses[candidate] != true) && (candidate != _owner)) {
            _knownAddresses[candidate] = true;
            _addresses[_addressesLength] = candidate;
            _addressesLength++;
            return true;
        }
        return false;
    }


    function period() public view returns (uint256) {
        return _period;
    }

    function poolBalance() public view returns (uint256) {
        return _poolBalance.div(_unitsPerToken);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account].div(_unitsPerToken);
    }

    function processBreedersBeforeTransfer(address from, address to, uint256 units) private {

        // process sender
        // if we have no current snapshot, make it
        // snapshot is balance before sending
        if(_breeders[from].snapshotPeriod < _period) {
            _breeders[from].snapshotBalance = _balances[from];
            _breeders[from].snapshotPeriod = _period;
        } else {
            // snapshot is same period, set balance reduced by units (= current balance)
            _breeders[from].snapshotBalance = _balances[from].sub(units);
        }

        // process receiver
        // if we have no current snapshot, make it
        // snapshot is balance before receiving
        if(_breeders[to].snapshotPeriod < _period) {
            _breeders[to].snapshotBalance = _balances[to];
            _breeders[to].snapshotPeriod = _period;
        } else {
            // snapshot is same period, nothing to do -> new tokens have to rest at least 1 period
            // later in breeding we have also to check the snapshort period and update the balance if < to take care of no transfer/no updated snapshot balance situation
            // (else will be removed)
        }
    }

    function transfer(address recipient, uint256 value) public validRecipient(recipient) returns (bool) {
        require(((_lockTransfer == false) || isOwnerOrWhitelisted(msg.sender)), 'token transfer is locked');
        uint256 units = value.mul(_unitsPerToken);
        uint256 newSenderBalance = _balances[msg.sender].sub(units);
        processBreedersBeforeTransfer(msg.sender, recipient, units);
        _balances[msg.sender] = newSenderBalance;
        _balances[recipient] = _balances[recipient].add(units);
        acquaintAddress(recipient);
        emit Transfer(msg.sender, recipient, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public validRecipient(to) returns (bool) {
        require(((_lockTransfer == false) || isOwnerOrWhitelisted(msg.sender)), 'token transfer is locked');
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
        uint256 units = value.mul(_unitsPerToken);
        processBreedersBeforeTransfer(from, to, units);
        uint256 newSenderBalance = _balances[from].sub(units);
        _balances[from] = newSenderBalance;
        _balances[to] = _balances[to].add(units);
        acquaintAddress(to);
        emit Transfer(from, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _allowances[msg.sender][spender] = _allowances[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = _allowances[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowances[msg.sender][spender] = 0;
        } else {
            _allowances[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }
}
