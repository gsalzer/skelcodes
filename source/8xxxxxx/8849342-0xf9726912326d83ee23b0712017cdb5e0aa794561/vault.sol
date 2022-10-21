//Copyright Octobase.co 2019
pragma solidity ^0.5.1;
import "./statuscodes.sol";
import "./safemath.sol";
import "./interfaces.sol";
import "./octomath.sol";
import "./storage.sol";

interface Erc20Token
{
    function transfer(address _to, uint256 amount)
        external
        returns (bool success);
}

contract VaultProxy
{
    address public delegate;
    bool public alwaysDelegateCall = false;
    address payable public signer;

    event Receive(address _sender, uint256 _amount);

    constructor (address _delegate, address payable _signer)
        public
    {
        delegate = _delegate;
        signer = _signer;
    }

    function ()
        external
        payable
    {
        if (alwaysDelegateCall || msg.value == 0 || msg.sender == signer)
        {
            assembly
            {
                let _target := sload(0)
                calldatacopy(0x0, 0x0, calldatasize)
                let result := delegatecall(gas, _target, 0x0, calldatasize, 0x0, 0)
                returndatacopy(0x0, 0x0, returndatasize)
                switch result case 0 {revert(0, 0)} default {return (0, returndatasize)}
            }
        }
        else
        {
            emit Receive(msg.sender, msg.value);
        }
    }
}

contract VaultBase { }

contract Vault is IVault
{
    using SafeMath for uint256;

    // CG: These 3 state entries *must* be here *in this order* and *must* be *the only* state, because it proxy VaultProxy.
    // CG: BEGIN STATE
    address public delegate;
    bool public alwaysDelegateCall;
    address payable public signer;
    // CG: END STATE

    struct Limit
    {
        uint256 max;
        uint256 spent;
        uint256 startDateUtc;
        uint256 windowSeconds;
        uint256 lastLimitWindow;
        LimitState state;
    }

    struct ChangeLimitProposal
    {
        uint256 executionDate;
        uint256 max;
        uint256 startDateUtc;
        uint256 windowSeconds;
    }

    event InitVault(
        uint256 max,
        uint256 startDateUtc,
        uint256 windowSeconds);
    event InitErc20Limit(
        address indexed tokenContract,
        uint256 max,
        uint256 startDateUtc,
        uint256 windowSeconds);
    event SendWei(address to, uint256 amount);
    event SendErc20(
        address tokenContract,
        address to,
        uint256 amount);
    event ProposeWeiLimitChange(
        uint256 proposalCooldownSeconds,
        uint256 max,
        uint256 startDateUtc,
        uint256 windowSeconds);
    event ProposeErc20LimitChange(
        uint256 proposalCooldownSeconds,
        address indexed tokenContract,
        uint256 max,
        uint256 startDateUtc,
        uint256 windowSeconds);
    event ProposeUpgrade(uint256 cooldown, address indexed implementation);
    event ExecuteUpgrade(address executor, address indexed implementation);
    event Receive(address _sender, uint256 _amount);

    function getSigner()
        public
        view
        returns (address)
    {
        return getStore().getAddress("signer");
    }

    modifier onlySigner()
    {
        require(msg.sender == signer, "Only signer may call this");
        _;
    }

    constructor() public { }

    function()
        external
        payable
    {
        emit Receive(msg.sender, msg.value);
    }

    function getLimit(address _tokenAddress)
        external
        view
        returns (
            uint256 max,
            uint256 spent,
            uint256 startDateUtc,
            uint256 lastLimitWindow,
            uint256 windowSeconds,
            LimitState state)
    {
        Limit memory limit = privateGetLimit(_tokenAddress);
        uint256 currentLimitWindow = getCurrentLimitWindow(limit);
        return (
            limit.max,
            limit.lastLimitWindow < currentLimitWindow ? 0 : limit.spent,
            limit.startDateUtc,
            limit.windowSeconds,
            currentLimitWindow,
            limit.state);
    }

    function privateGetLimit(address _tokenAddress)
        private
        view
        returns(Limit memory _result)
    {
        Storage store = getStore();
        (
            _result.max,
            _result.spent,
            _result.startDateUtc,
            _result.windowSeconds,
            _result.lastLimitWindow,
            _result.state) = store.getLimit(_tokenAddress);
    }

    function privateSetLimit(address _tokenAddress, Limit memory _limit)
        private
    {
        Storage store = getStore();
        store.setLimit(
            _tokenAddress,
            _limit.max,
            _limit.spent,
            _limit.startDateUtc,
            _limit.windowSeconds,
            _limit.lastLimitWindow,
            _limit.state);
    }

    function privateInitLimit(
        address _tokenAddress,
        uint256 _max,
        uint256 _startDateUtc,
        uint256 _windowSeconds)
        private
        returns (bool success)
    {
        Limit memory limit = privateGetLimit(_tokenAddress);

        if (limit.state != LimitState.Uninitialized ||
            _startDateUtc > block.timestamp ||
            _windowSeconds == 0)
        {
            return (false);
        }
        else
        {
            limit.max = _max;
            limit.spent = 0;
            limit.lastLimitWindow = 0;
            limit.startDateUtc = _startDateUtc;
            limit.windowSeconds = _windowSeconds;
            limit.state = LimitState.NoProposal;
            privateSetLimit(_tokenAddress, limit);
            return true;
        }
    }

    function initVault(
            uint256 _weiMax,
            uint256 _weiStartDateUtc,
            uint256 _weiWindowSeconds)
        external
        onlySigner
        returns (StatusCodes.Status status)
    {
        bool success = privateInitLimit(address(0x0), _weiMax, _weiStartDateUtc, _weiWindowSeconds);
        require(success, "Limit init failed");
        emit InitVault(_weiMax, _weiStartDateUtc, _weiWindowSeconds);
        return StatusCodes.Status.Success;
    }

    function initErc20Limit(
            address _tokenAddress,
            uint256 _max,
            uint256 _startDateUtc,
            uint256 _windowSeconds)
        external
        onlySigner
        returns (StatusCodes.Status status)
    {
        require(_tokenAddress != address(0x0), "Cannot init Eth limt here");
        bool success = privateInitLimit(_tokenAddress, _max, _startDateUtc, _windowSeconds);
        require(success, "Limit init failed");
        emit InitErc20Limit(_tokenAddress, _max, _startDateUtc, _windowSeconds);
        return StatusCodes.Status.Success;
    }

    function sendWei(address payable _to, uint256 _amount)
        external
        onlySigner
        returns (StatusCodes.Status status)
    {
        bool success = spendOnLimit(address(0x0), _amount);
        require(success, "Limit violated");
        (success,) = _to.call.value(_amount)("");
        require(success, "sendWei unscucessful");
        emit SendWei(_to, _amount);
        return StatusCodes.Status.Success;
    }

    function sendErc20(
            address _tokenAddress,
            address _to,
            uint256 _amount)
        external
        onlySigner
        returns (StatusCodes.Status status)
    {
        require(_tokenAddress != address(0x0), "Please use the sendWei function");
        bool success = spendOnLimit(_tokenAddress, _amount);
        require(success, "Limit violated");
        Erc20Token token = Erc20Token(_tokenAddress);
        success = token.transfer(_to, _amount);
        require(success, "sendWei unscucessful");
        emit SendErc20(_tokenAddress, _to, _amount);
        return StatusCodes.Status.Success;
    }

    function proposeWeiLimitChange(
            uint256 _max,
            uint256 _startDateUtc,
            uint256 _windowSeconds)
        external
        onlySigner
        returns (StatusCodes.Status status)
    {
        bool success = proposeLimitChange(7 days, address(0x0), _max, _startDateUtc, _windowSeconds);
        require(success, "Limit change proposal failed");
        emit ProposeWeiLimitChange(7 days, _max, _startDateUtc, _windowSeconds);
        return StatusCodes.Status.Success;
    }

    function proposeErc20LimitChange(
            address _tokenAddress,
            uint256 _max,
            uint256 _startDateUtc,
            uint256 _windowSeconds)
        external
        onlySigner
        returns (StatusCodes.Status status)
    {
        require(_tokenAddress != address(0x0), "Cannot set wei limit with this method");
        bool success = proposeLimitChange(7 days, _tokenAddress, _max, _startDateUtc, _windowSeconds);
        require(success, "store.proposeLimitChange failed.");
        emit ProposeErc20LimitChange(7 days, _tokenAddress, _max, _startDateUtc, _windowSeconds);
        return StatusCodes.Status.Success;
    }

    function proposeUpgrade(address _implementation)
        external
        onlySigner
        returns (StatusCodes.Status status)
    {
        ISigner signerWrapper = ISigner(signer);
        (bool isActive, , address owner) = signerWrapper.getNonces();
        require(isActive, "Signer is not active");
        bool success = setUpgradeProposal(7 days, _implementation, owner);
        require(success, "Set upgrade proposal failed");
        emit ProposeUpgrade(7 days, _implementation);
        return StatusCodes.Status.Success;
    }

    function setUpgradeProposal(
            uint256 _cooldownPeriod,
            address _implementation,
            address _owner)
        internal
        returns (bool success)
    {
        UpgradeProposal memory proposal = internalGetUpgradeProposal();
        proposal.executionDate = block.timestamp.add(_cooldownPeriod);
        proposal.implementation = _implementation;
        proposal.dateProposed = block.timestamp;
        proposal.owner = _owner;
        proposal.isExecuted = false;
        internalSetUpgradeProposal(proposal);
        return true;
    }

    function executeUpgrade()
        external
        returns (StatusCodes.Status status)
    {
        (bool isActive, , address owner) = ISigner(signer).getNonces();
        require(isActive, "Signer is not active");
        UpgradeProposal memory proposal = internalGetUpgradeProposal();

        if (!proposal.isExecuted
                && proposal.executionDate <= block.timestamp
                && proposal.implementation != address(0x0)
                && owner == proposal.owner)
        {
            proposal.isExecuted = true;
            delegate = proposal.implementation;
            internalSetUpgradeProposal(proposal);
            emit ExecuteUpgrade(msg.sender, proposal.implementation);
            return StatusCodes.Status.Success;
        }
        else
        {
            revert("Upgrade execution failed");
        }
    }

    struct UpgradeProposal
    {
        uint256 executionDate;
        address implementation;
        uint256 dateProposed;
        address owner;
        bool isExecuted;
    }

    function internalSetUpgradeProposal(UpgradeProposal memory _proposal)
        internal
    {
        Storage store = getStore();
        store.setUpgradeProposal(
            _proposal.executionDate,
            _proposal.implementation,
            _proposal.dateProposed,
            _proposal.owner,
            _proposal.isExecuted);
    }

    function getUpgradeProposal()
        public
        view
        returns (
            uint256 _executionDate,
            address _implementation,
            uint256 _dateProposed,
            address _owner,
            bool _isExecuted)
    {
        UpgradeProposal memory result = internalGetUpgradeProposal();
        return(
            result.executionDate,
            result.implementation,
            result.dateProposed,
            result.owner,
            result.isExecuted
        );
    }

    function internalGetUpgradeProposal()
        internal
        view
        returns (UpgradeProposal memory _result)
    {
        Storage store = getStore();
        (
            _result.executionDate,
            _result.implementation,
            _result.dateProposed,
            _result.owner,
            _result.isExecuted) = store.getUpgradeProposal();
    }

    function getProposal(address _tokenAddress)
        external
        view
        returns (
            uint256 executionDate,
            uint256 max,
            uint256 startDateUtc,
            uint256 windowSeconds)
    {
        ChangeLimitProposal memory proposal = privateGetChangeLimitProposal(_tokenAddress);
        return (
            proposal.executionDate,
            proposal.max,
            proposal.startDateUtc,
            proposal.windowSeconds);
    }

    function privateGetChangeLimitProposal(address _tokenAddress)
        private
        view
        returns(ChangeLimitProposal memory _result)
    {
        Storage store = getStore();
        (
            _result.executionDate,
            _result.max,
            _result.startDateUtc,
            _result.windowSeconds) = store.getChangeLimitProposal(_tokenAddress);
    }

    function privateSetChangeLimitProposal(address _tokenAddress, ChangeLimitProposal memory _proposal)
        private
    {
        Storage store = getStore();
        store.setChangeLimitProposal(
            _tokenAddress,
            _proposal.executionDate,
            _proposal.max,
            _proposal.startDateUtc,
            _proposal.windowSeconds);
    }

    function proposeLimitChange(
            uint256 _proposalCooldownSeconds,
            address _tokenAddress,
            uint256 _maxLimit,
            uint256 _startDateUtc,
            uint256 _windowSeconds)
        private
        returns (bool success)
    {
        require(_startDateUtc <= block.timestamp, "Cannot start in the future");
        require(_windowSeconds > 0, "Cannot have a spending period of 0");

        Limit memory limit = privateGetLimit(_tokenAddress);
        if (limit.state == LimitState.Uninitialized)
        {
            return false;
        }
        else
        {
            ChangeLimitProposal memory proposal = privateGetChangeLimitProposal(_tokenAddress);
            if (limit.state == LimitState.ProposalPending)
            {
                if (
                    (proposal.executionDate <= block.timestamp)
                    && (ISigner(signer).checkFreezeInvalidation(proposal.executionDate.sub(7 days), proposal.executionDate)))
                {
                    limit.max = proposal.max;
                    limit.startDateUtc = proposal.startDateUtc;
                    limit.windowSeconds = proposal.windowSeconds;
                    limit.state = LimitState.NoProposal;
                    limit.lastLimitWindow = getCurrentLimitWindow(limit);
                }
            }

            proposal.executionDate = block.timestamp.add(_proposalCooldownSeconds);
            proposal.max = _maxLimit;
            proposal.startDateUtc = _startDateUtc;
            proposal.windowSeconds = _windowSeconds;

            limit.state = LimitState.ProposalPending;

            if (octomath.ceilDiv(_maxLimit.mul(limit.windowSeconds), _windowSeconds) <= limit.max)
            {
                limit.max = _maxLimit;
                limit.startDateUtc = _startDateUtc;
                limit.windowSeconds = _windowSeconds;
                limit.state = LimitState.NoProposal;
                limit.lastLimitWindow = getCurrentLimitWindow(limit);
                proposal.executionDate = 0;
                proposal.max = 0;
                proposal.startDateUtc = 0;
                proposal.windowSeconds = 0;
            }

            privateSetLimit(_tokenAddress, limit);
            privateSetChangeLimitProposal(_tokenAddress, proposal);
            return true;
        }
    }

    function spendOnLimit(address _tokenAddress, uint256 _amount)
        private
        returns (bool success)
    {
        Limit memory limit = privateGetLimit(_tokenAddress);
        uint256 currentLimitWindow = getCurrentLimitWindow(limit);

        if (limit.state == LimitState.ProposalPending)
        {
            ChangeLimitProposal memory proposal = privateGetChangeLimitProposal(_tokenAddress);
            if ((proposal.executionDate <= block.timestamp)
               && (ISigner(signer).checkFreezeInvalidation(proposal.executionDate.sub(7 days), proposal.executionDate)))
            {
                limit.max = proposal.max;
                limit.spent = 0;
                limit.lastLimitWindow = 0;
                limit.startDateUtc = proposal.startDateUtc;
                limit.windowSeconds = proposal.windowSeconds;
                limit.state = LimitState.NoProposal;
            }
        }

        require(
            limit.state != LimitState.Uninitialized &&
            limit.windowSeconds > 0 &&
            limit.startDateUtc <= block.timestamp,
            "Invalid limit");

        if (limit.lastLimitWindow < currentLimitWindow)
        {
            limit.spent = 0;
            limit.lastLimitWindow = currentLimitWindow;
        }
        require(limit.max >= limit.spent, "Can't spend more than limit");
        uint256 available = limit.max.sub(limit.spent);
        require(available >= _amount, "Can't spend more than balance");
        limit.spent = limit.spent.add(_amount);
        // the line below is true, but not necessary, leaving it here for clarity that the
        // limit.lastLimitWindow = currentLimitWindow;
        privateSetLimit(_tokenAddress, limit);
        return true;
    }

    function getCurrentLimitWindow(Limit memory _limit)
        private
        view
        returns (uint _currentLimitWindow)
    {
        require(
            block.timestamp > _limit.startDateUtc,
            "Cannot compute the limit window for a future dated start time");
        return block.timestamp.sub(_limit.startDateUtc).div(_limit.windowSeconds);
    }

    function getStore()
        private
        pure
        returns (Storage store)
    {
        return Storage(0x1234567890AbcdeffedcBA98765432123454321F);
    }

    function octobaseType()
        external
        pure
        returns (uint16 typeId)
    {
        return 2;
    }

    function octobaseTypeVersion()
        external
        pure
        returns (uint32 typeVersion)
    {
        return 1;
    }
}
