pragma solidity >=0.4.25 <0.6.0;
pragma experimental ABIEncoderV2;


contract Modifiable {
    
    
    
    modifier notNullAddress(address _address) {
        require(_address != address(0));
        _;
    }

    modifier notThisAddress(address _address) {
        require(_address != address(this));
        _;
    }

    modifier notNullOrThisAddress(address _address) {
        require(_address != address(0));
        require(_address != address(this));
        _;
    }

    modifier notSameAddresses(address _address1, address _address2) {
        if (_address1 != _address2)
            _;
    }
}

contract SelfDestructible {
    
    
    
    bool public selfDestructionDisabled;

    
    
    
    event SelfDestructionDisabledEvent(address wallet);
    event TriggerSelfDestructionEvent(address wallet);

    
    
    
    
    function destructor()
    public
    view
    returns (address);

    
    
    function disableSelfDestruction()
    public
    {
        
        require(destructor() == msg.sender);

        
        selfDestructionDisabled = true;

        
        emit SelfDestructionDisabledEvent(msg.sender);
    }

    
    function triggerSelfDestruction()
    public
    {
        
        require(destructor() == msg.sender);

        
        require(!selfDestructionDisabled);

        
        emit TriggerSelfDestructionEvent(msg.sender);

        
        selfdestruct(msg.sender);
    }
}

contract Ownable is Modifiable, SelfDestructible {
    
    
    
    address public deployer;
    address public operator;

    
    
    
    event SetDeployerEvent(address oldDeployer, address newDeployer);
    event SetOperatorEvent(address oldOperator, address newOperator);

    
    
    
    constructor(address _deployer) internal notNullOrThisAddress(_deployer) {
        deployer = _deployer;
        operator = _deployer;
    }

    
    
    
    
    function destructor()
    public
    view
    returns (address)
    {
        return deployer;
    }

    
    
    function setDeployer(address newDeployer)
    public
    onlyDeployer
    notNullOrThisAddress(newDeployer)
    {
        if (newDeployer != deployer) {
            
            address oldDeployer = deployer;
            deployer = newDeployer;

            
            emit SetDeployerEvent(oldDeployer, newDeployer);
        }
    }

    
    
    function setOperator(address newOperator)
    public
    onlyOperator
    notNullOrThisAddress(newOperator)
    {
        if (newOperator != operator) {
            
            address oldOperator = operator;
            operator = newOperator;

            
            emit SetOperatorEvent(oldOperator, newOperator);
        }
    }

    
    
    function isDeployer()
    internal
    view
    returns (bool)
    {
        return msg.sender == deployer;
    }

    
    
    function isOperator()
    internal
    view
    returns (bool)
    {
        return msg.sender == operator;
    }

    
    
    
    function isDeployerOrOperator()
    internal
    view
    returns (bool)
    {
        return isDeployer() || isOperator();
    }

    
    
    modifier onlyDeployer() {
        require(isDeployer());
        _;
    }

    modifier notDeployer() {
        require(!isDeployer());
        _;
    }

    modifier onlyOperator() {
        require(isOperator());
        _;
    }

    modifier notOperator() {
        require(!isOperator());
        _;
    }

    modifier onlyDeployerOrOperator() {
        require(isDeployerOrOperator());
        _;
    }

    modifier notDeployerOrOperator() {
        require(!isDeployerOrOperator());
        _;
    }
}

library SafeMathUintLib {
    function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        
        uint256 c = a / b;
        
        return c;
    }

    function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    
    
    
    function clamp(uint256 a, uint256 min, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : ((a < min) ? min : a);
    }

    function clampMin(uint256 a, uint256 min)
    public
    pure
    returns (uint256)
    {
        return (a < min) ? min : a;
    }

    function clampMax(uint256 a, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : a;
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        
        
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        
        
        
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        
        

        
        
        
        
        
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract TokenMultiTimelock is Ownable {
    using SafeMathUintLib for uint256;
    using SafeERC20 for IERC20;

    
    
    
    struct Release {
        uint256 blockNumber;
        uint256 earliestReleaseTime;
        uint256 amount;
        uint256 totalAmount;
        bool done;
    }

    
    
    
    IERC20 public token;
    address public beneficiary;

    Release[] public releases;
    uint256 public totalReleasedAmount;
    uint256 public totalLockedAmount;
    uint256 public executedReleasesCount;

    
    
    
    event SetTokenEvent(IERC20 token);
    event SetBeneficiaryEvent(address beneficiary);
    event DefineReleaseEvent(uint256 blockNumber, uint256 earliestReleaseTime, uint256 amount,
        uint256 totalAmount, bool done);
    event SetReleaseBlockNumberEvent(uint256 index, uint256 blockNumber);
    event ReleaseEvent(uint256 index, uint256 blockNumber, uint256 earliestReleaseTime,
        uint256 actualReleaseTime, uint256 amount);

    
    
    
    constructor(address deployer)
    Ownable(deployer)
    public
    {
    }

    
    
    
    
    
    function setToken(IERC20 _token)
    public
    onlyOperator
    notNullOrThisAddress(address(_token))
    {
        
        require(address(token) == address(0), "Token previously set [TokenMultiTimelock.sol:79]");

        
        token = _token;

        
        emit SetTokenEvent(token);
    }

    
    
    function setBeneficiary(address _beneficiary)
    public
    onlyOperator
    notNullAddress(_beneficiary)
    {
        
        beneficiary = _beneficiary;

        
        emit SetBeneficiaryEvent(beneficiary);
    }

    
    
    function defineReleases(Release[] memory _releases)
    onlyOperator
    public
    {
        
        require(address(token) != address(0), "Token not initialized [TokenMultiTimelock.sol:109]");

        
        for (uint256 i = 0; i < _releases.length; i++) {
            
            totalLockedAmount += _releases[i].amount;

            
            
            require(token.balanceOf(address(this)) >= totalLockedAmount, "Total locked amount overrun [TokenMultiTimelock.sol:118]");

            
            releases.push(_releases[i]);

            
            emit DefineReleaseEvent(_releases[i].blockNumber, _releases[i].earliestReleaseTime, _releases[i].amount,
                totalLockedAmount, _releases[i].done);
        }
    }

    
    
    function releasesCount()
    public
    view
    returns (uint256)
    {
        return releases.length;
    }

    
    
    
    function setReleaseBlockNumber(uint256 index, uint256 blockNumber)
    public
    onlyBeneficiary
    {
        
        require(!releases[index].done, "Release previously done [TokenMultiTimelock.sol:147]");

        
        releases[index].blockNumber = blockNumber;

        
        emit SetReleaseBlockNumberEvent(index, blockNumber);
    }

    
    
    
    
    function releaseIndexByBlockNumber(uint256 blockNumber)
    public
    view
    returns (int256)
    {
        for (uint256 i = releases.length; i > 0;) {
            i = i.sub(1);
            if (0 < releases[i].blockNumber && releases[i].blockNumber <= blockNumber)
                return int256(i);
        }
        return - 1;
    }

    
    
    function release(uint256 index)
    public
    onlyBeneficiary
    {
        
        Release storage _release = releases[index];

        
        require(0 < _release.amount, "Release amount not strictly positive [TokenMultiTimelock.sol:183]");

        
        require(!_release.done, "Release previously done [TokenMultiTimelock.sol:186]");

        
        require(block.timestamp >= _release.earliestReleaseTime, "Block time stamp less than earliest release time [TokenMultiTimelock.sol:189]");

        
        totalReleasedAmount = totalReleasedAmount.add(_release.amount);

        
        _release.totalAmount = totalReleasedAmount;

        
        _release.done = true;

        
        if (0 == _release.blockNumber)
            _release.blockNumber = block.number;

        
        executedReleasesCount = executedReleasesCount.add(1);

        
        totalLockedAmount = totalLockedAmount.sub(_release.amount);

        
        token.safeTransfer(beneficiary, _release.amount);

        
        emit ReleaseEvent(index, _release.blockNumber, _release.earliestReleaseTime, block.timestamp, _release.amount);
    }

    
    
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Message sender not beneficiary [TokenMultiTimelock.sol:220]");
        _;
    }
}

interface BalanceRecordable {
    
    function balanceRecordsCount(address account)
    external
    view
    returns (uint256);

    
    function recordBalance(address account, uint256 index)
    external
    view
    returns (uint256);

    
    function recordBlockNumber(address account, uint256 index)
    external
    view
    returns (uint256);

    
    function recordIndexByBlockNumber(address account, uint256 blockNumber)
    external
    view
    returns (int256);
}

contract RevenueTokenManager is TokenMultiTimelock, BalanceRecordable {
    using SafeMathUintLib for uint256;

    
    
    
    constructor(address deployer)
    public
    TokenMultiTimelock(deployer)
    {
    }

    
    
    
    
    
    function balanceRecordsCount(address)
    external
    view
    returns (uint256)
    {
        return executedReleasesCount;
    }

    
    
    
    function recordBalance(address, uint256 index)
    external
    view
    returns (uint256)
    {
        return releases[index].totalAmount;
    }

    
    
    
    function recordBlockNumber(address, uint256 index)
    external
    view
    returns (uint256)
    {
        return releases[index].blockNumber;
    }

    
    
    
    
    function recordIndexByBlockNumber(address, uint256 blockNumber)
    external
    view
    returns (int256)
    {
        return releaseIndexByBlockNumber(blockNumber);
    }
}
