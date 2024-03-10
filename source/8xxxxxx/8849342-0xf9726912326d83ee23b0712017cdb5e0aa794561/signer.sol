//Copyright Octobase.co 2019

pragma solidity ^0.5.1;
import "./statuscodes.sol";
import "./safemath.sol";
import "./interfaces.sol";
import "./storage.sol";

contract SignerProxy
{
    address public delegate;

    constructor (address _delegate)
        public
    {
        delegate = _delegate;
    }

    function()
        external
        payable
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
}

contract SignerBase
{
    using SafeMath for uint256;

    address public delegate; // CG: Since this is the proxy pattern (for SignerProxy) this state *must* be here and it *must* be *the only* state

    struct SignerState
    {
        address parentFactory;
        ISigner.AccessState accessState;
        address owner;
        address roundTable;
        address vault;
        uint256 callNonce;
    }

    struct UpgradeProposal
    {
        uint256 executionDate;
        address implementation;
        uint256 dateProposed;
        address owner;
        bool isExecuted;
    }

    function writeState(SignerState memory _in)
        internal
    {
        getStore().setSignerState(
            _in.parentFactory,
            _in.accessState,
            _in.owner,
            _in.roundTable,
            _in.vault,
            _in.callNonce);
    }

    function readState()
        internal
        view
        returns(SignerState memory)
    {
        SignerState memory result;
        (result.parentFactory,
        result.accessState,
        result.owner,
        result.roundTable,
        result.vault,
        result.callNonce) = getStore().getSignerState();
        return result;
    }

    function getState()
        external
        view
        returns (
            address parentFactory,
            ISigner.AccessState accessState,
            address owner,
            IRoundTable roundTable,
            IVault vault,
            uint256 callNonce)
    {
        SignerState memory state = readState();
        return (
            state.parentFactory,
            state.accessState,
            state.owner,
            IRoundTable(state.roundTable),
            IVault(state.vault),
            state.callNonce);
    }

    constructor() public { }

    function enc(string memory _inputString)
        public
        pure
        returns (bytes32 _encodedString)
    {
        return keccak256(abi.encode(_inputString));
    }

    function encMap(address _address, string memory _member)
        public
        pure
        returns(bytes32)
    {
        return keccak256(abi.encode(_address, _member));
    }

    function encArray(uint256 _index, string memory _member)
        public
        pure
        returns(bytes32)
    {
        return keccak256(abi.encode(_index, _member));
    }

    function getUsedOwnerKey(address _owner)
        public
        view
        returns(bool)
    {
        return getStore().getBool(encMap(_owner, "usedOwnerKeys"));
    }

    function getFreezeDate(uint256 _freezeIndex)
        public
        view
        returns(uint256)
    {
        return getStore().getUint256(encArray(_freezeIndex, "freezeDates"));
    }

    function getFreezeIndex()
        public
        view
        returns(uint256)
    {
        return getStore().getUint256("freezeIndex");
    }

    function getParentFactory()
        public
        view
        returns (string memory)
    {
        return getStore().getString("parentFactory");
    }

    function getAccessState()
        public
        view
        returns (ISigner.AccessState)
    {
        return ISigner.AccessState(getStore().getUint256("accessState"));
    }

    function getNonces()
        external
        view
        returns (bool isActive, uint256 callNonce, address owner)
    {
        SignerState memory state = readState();
        return (state.accessState == ISigner.AccessState.Active, state.callNonce, state.owner);
    }

    function getStore()
        public
        pure
        returns (Storage store)
    {
        return Storage(0x1234567890AbcdeffedcBA98765432123454321F);
    }

    function getOwner()
        public
        view
        returns (address payable)
    {
        return address(uint(getStore().getAddress("owner")));
    }

    function getRoundTable()
        public
        view
        returns (address)
    {
        return address(uint(getStore().getAddress("roundTable")));
    }

    function getVault()
        public
        view
        returns (IVault _vault)
    {
        return IVault(uint(getStore().getAddress("vault")));
    }

    function getCallNonce()
        public
        view
        returns(uint256 _callNonce)
    {
        return getStore().getUint256("callNonce");
    }

    function getOctobase()
        public
        pure
        returns (address payable)
    {
        return 0xB956B0ba89aD213EbbA1eaFE11Ca6E0483d6DCFE;
        //return address(uint(getStore().getAddress("octobase")));
    }

    function getUpgradeProposal()
        external
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
        returns (UpgradeProposal memory)
    {
        Storage store = getStore();
        return UpgradeProposal(
            store.getUint256(enc("UpgradeProposal.executionDate")),
            store.getAddress(enc("UpgradeProposal.implementation")),
            store.getUint256(enc("UpgradeProposal.dateProposed")),
            store.getAddress(enc("UpgradeProposal.owner")),
            store.getBool(enc("UpgradeProposal.isExecuted")));
    }

    function setUsedOwnerKey(address _owner)
        internal
    {
        getStore().setBool(encMap(_owner, "usedOwnerKeys"), true);
    }

    function pushFreezeDate()
        internal
    {
        Storage store = getStore();
        uint256 freezeIndex = store.getUint256("freezeIndex");
        store.setUint256(encArray(freezeIndex, "freezeDates"), block.timestamp);
        store.setUint256("freezeIndex", freezeIndex.add(1));
    }

    function setUpgradeProposal(
            uint256 _executionDate,
            address _implementation,
            address _owner,
            uint256 _dateProposed,
            bool _isExecuted)
        internal
    {
        Storage store = getStore();
        store.setUint256(enc("UpgradeProposal.executionDate"), _executionDate);
        store.setAddress(enc("UpgradeProposal.implementation"), _implementation);
        store.setUint256(enc("UpgradeProposal.dateProposed"), _dateProposed);
        store.setAddress(enc("UpgradeProposal.owner"), _owner);
        store.setBool(enc("UpgradeProposal.isExecuted"), _isExecuted);
    }

    function internalSetUpgradeProposal(UpgradeProposal memory _proposal)
        internal
    {
        Storage store = getStore();
        store.setUint256(enc("UpgradeProposal.executionDate"), _proposal.executionDate);
        store.setAddress(enc("UpgradeProposal.implementation"), _proposal.implementation);
        store.setUint256(enc("UpgradeProposal.dateProposed"), _proposal.dateProposed);
        store.setAddress(enc("UpgradeProposal.owner"), _proposal.owner);
        store.setBool(enc("UpgradeProposal.isExecuted"), _proposal.isExecuted);
    }
}

contract Signer is SignerBase
{
    using SafeMath for uint256;

    event Claim(address owner);
    event Initiation(IVault vault, address owner);
    event OwnerChange(address owner);
    event RoundTableChange(IRoundTable roundTable);
    event Forward(
        string _msg,
        address indexed to,
        bytes result,
        bool success);
    event Freeze(address indexed freezer, bool wasFrozen);
    event MetaFreeze(
        address indexed relayer,
        address indexed rewardRecipient,
        address rewardToken,
        uint256 rewardAmount,
        address indexed freezer);
    event MetaCall(
        string _msg,
        address indexed relayer,
        address indexed rewardRecipient,
        address rewardToken,
        uint256 rewardAmount,
        bytes result,
        bool success);
    event WalletFee(
        address indexed provider,
        address rewardToken,
        uint256 rewardAmount);
    event ProposeUpgrade(uint256 cooldown, address newImplementation);
    event ExecuteUpgrade(address indexed executor, address newImplementation);
    event LogProposeNewGuardians(
        IRoundTable _currentRoundTable,
        IRoundTable _proposedRoundTable,
        uint256 _proposalId);

    constructor() public { }

    modifier onlySelf()
    {
        require(msg.sender == address(this), "Only self");
        _;
    }

    function()
        external
        payable
    {
        revert("No fallbacks");
    }

    function claim(address _owner)
        external
        returns (StatusCodes.Status status)
    {
        SignerState memory state = readState();
        require(state.owner == address(0x0), "Owner can't be 0x0");
        require(state.accessState == ISigner.AccessState.Uninitiated, "Signer already initiated");
        emit Claim(_owner);

        require(getUsedOwnerKey(_owner) == false, "Keys cannot be reused");
        state.owner = _owner;
        setUsedOwnerKey(_owner);

        writeState(state);
        return StatusCodes.Status.Success;
    }

    function init(address _owner,
            IVault _vault,
            uint _weiMaxLimit,
            uint _weiLimitStartDateUtc,
            uint _weiLimitWindowSeconds)
        external
        returns (StatusCodes.Status status)
    {
        SignerState memory state = readState();
        require(msg.sender == state.owner, "Not the owner");
        require(state.accessState == ISigner.AccessState.Uninitiated, "Uninitiated");

        StatusCodes.Status callStatus = _vault.initVault(_weiMaxLimit, _weiLimitStartDateUtc, _weiLimitWindowSeconds);
        require(callStatus == StatusCodes.Status.Success, "Vault not inititialized");

        state.owner = _owner;
        setUsedOwnerKey(_owner);

        state.vault = address(_vault);
        state.accessState = ISigner.AccessState.Active;
        emit Initiation(_vault, _owner);

        writeState(state);
        return StatusCodes.Status.Success;
    }

    function changeOwner(address _newOwner)
        external
        returns (StatusCodes.Status status)
    {
        SignerState memory state = readState();
        require(msg.sender == address(state.roundTable), "Only round table");

        require(getUsedOwnerKey(_newOwner) == false, "Keys cannot be reused");
        state.owner = _newOwner;
        setUsedOwnerKey(state.owner);

        state.accessState = ISigner.AccessState.Active;
        emit OwnerChange(_newOwner);

        writeState(state);
        return StatusCodes.Status.Success;
    }

    function changeRoundTable(IRoundTable _newRoundTable)
        external
        returns (StatusCodes.Status status)
    {
        SignerState memory state = readState();

        require(msg.sender == address(state.roundTable), "Only round table");
        state.roundTable = address(_newRoundTable);
        emit RoundTableChange(_newRoundTable);

        writeState(state);
        return StatusCodes.Status.Success;
    }

    function appointGuardians(
            IRoundTableFactory _roundTableFactory,
            address[] calldata _guardians)
        external
        onlySelf
        returns (StatusCodes.Status status, IRoundTable roundTable)
    {
        SignerState memory state = readState();

        require(state.roundTable == address(0x0), "Already have guardians");
        (StatusCodes.Status code, IRoundTable createdRoundTable) = _roundTableFactory
            .produceRoundTable(
                ISigner(address(this)),
                _guardians);
        require(code == StatusCodes.Status.Success, "Factory unsuccessful");
        state.roundTable = address(createdRoundTable);
        emit RoundTableChange(createdRoundTable);

        writeState(state);
        return (code, createdRoundTable);
    }

    function proposeNewGuardians(
            IRoundTableFactory _roundTableFactory,
            address[] calldata _guardians)
        external
        onlySelf
        returns (
            StatusCodes.Status _status,
            uint256 _proposalId)
    {
        SignerState memory state = readState(); //no need to write this state again, all state changes are external

        IRoundTable rt = IRoundTable(state.roundTable);
        require(address(rt) != address(0x0), "No round table appointed yet");
        (StatusCodes.Status code, IRoundTable createdRoundTable) = _roundTableFactory
            .produceRoundTable(
                ISigner(address(this)),
                _guardians);
        require(code == StatusCodes.Status.Success, "Factory unsuccessful");
        (StatusCodes.Status status, uint256 proposalId) = rt.proposeAndSupportRoundTableChange(address(createdRoundTable));
        emit LogProposeNewGuardians(rt, createdRoundTable, proposalId);
        return (status, proposalId);
    }

    function forward(address _to, bytes calldata _data)
        external
        onlySelf
        returns (StatusCodes.Status status, bytes memory result)
    {
        require(_to != address(this), "Cannot forward to self");
        SignerState memory state = readState();
        require(
            state.accessState == ISigner.AccessState.Active || _to != state.vault,
            "Inaccessible when frozen");

        (bool isSuccess, bytes memory callResult) = _to.call(_data);

        emit Forward("Forward", _to, callResult, isSuccess);
        if (isSuccess)
        {
            return (StatusCodes.Status.Success, callResult);
        }
        else
        {
            return (StatusCodes.Status.Failure, callResult);
        }
    }

    function freeze(address _owner)
        external
        returns (StatusCodes.Status status)
    {
        SignerState memory state = readState();

        require(msg.sender == address(state.roundTable), "Only round table");
        require(_owner == state.owner, "Freeze nonce mismatch");

        if (state.accessState == ISigner.AccessState.Active)
        {
            state.accessState = ISigner.AccessState.Frozen;
            emit Freeze(msg.sender, false);

            pushFreezeDate();
            writeState(state);
            return (StatusCodes.Status.Success);
        }
        else if (state.accessState == ISigner.AccessState.Frozen)
        {
            emit Freeze(msg.sender, true);
            return (StatusCodes.Status.AlreadyDone);
        }
        else
        {
            revert("Invalid state");
        }
    }

    function metaCall(
            uint256 _callNonce,
            uint256 _callGas,
            uint256 _rewardAmount,
            address payable _rewardRecipient,
            address _rewardTokenAddress,
            bytes calldata _data,
            bytes calldata _signature)
        external
        payable
        returns (StatusCodes.Status status, bytes memory result)
    {
        require(_callGas > 0, "Insufficient vespine gas!");
        SignerState memory state = readState();

        require(state.accessState != ISigner.AccessState.Uninitiated, "Signer must be active");
        require(_callNonce == state.callNonce, "Incorrect callNonce");

        // Validate the Signer
        require(
            getSignatureAddress(
                metaCallHash(
                    _callNonce,
                    _callGas,
                    _rewardAmount,
                    _rewardTokenAddress,
                    _data),
                _signature) == state.owner,
            "Signature incorrect");

        // Vault ownership checks enforced by Vault, hence not included directly here

        // Reward the relayer with funds the Signer controls.
        uint256 rewardPay = payReward(state, _rewardTokenAddress, _rewardRecipient, _rewardAmount);

        require(gasleft() > _callGas, "Insufficient vespine gas!");

        // Execute the actual transaction
        (bool success, bytes memory resultData) = address(this).call.value(msg.value).gas(_callGas)(_data);

        // Ensure the callNonce increases
        if (success) state = readState(); // necessary since a successful call may have altered the state.
        state.callNonce = state.callNonce.add(1);

        // Output business event
        emit MetaCall(
            "Meta call",
            msg.sender,
            _rewardRecipient,
            _rewardTokenAddress,
            rewardPay,
            resultData,
            success);

        writeState(state);
        return (
            success ? StatusCodes.Status.Success : StatusCodes.Status.Failure,
            resultData);
    }

    function metaCallHash(
            uint256 _callNonce,
            uint256 _callGas,
            uint _rewardAmount,
            address _rewardTokenAddress,
            bytes memory _data)
        public
        view
        returns(bytes32 _hash)
    {
        return keccak256(
            abi.encodePacked(
                address(this),
                "metaCall",
                _callNonce,
                _callGas,
                _rewardAmount,
                _rewardTokenAddress,
                _data));
    }

    function metaFreeze(
            address _owner,
            address payable _rewardRecipient,
            address _rewardTokenAddress,
            uint _rewardAmount,
            bytes calldata _signature)
        external
        returns (StatusCodes.Status _statusCode)
    {
        SignerState memory state = readState();

        //Validate the Signer
        address signer = getSignatureAddress(
            metaFreezeHash(
                _owner,
                _rewardAmount,
                _rewardTokenAddress),
            _signature);
        require(signer == state.owner, "Signature incorrect");

        //Validate the owner
        require(_owner == state.owner, "owner incorrect");

        if (state.accessState == ISigner.AccessState.Active)
        {
            // Reward the relayer with funds the Signer controls.
            if (_rewardAmount > 0)
                payReward(state, _rewardTokenAddress, _rewardRecipient, _rewardAmount);

            state.accessState = ISigner.AccessState.Frozen;
            emit MetaFreeze(msg.sender, _rewardRecipient, _rewardTokenAddress, _rewardAmount, signer);
            emit Freeze(signer, false);

            pushFreezeDate();
            writeState(state);
            return StatusCodes.Status.Success;
        }
        else if (state.accessState == ISigner.AccessState.Frozen)
        {
            emit MetaFreeze(msg.sender, _rewardRecipient, _rewardTokenAddress, 0, signer);
            emit Freeze(signer, true);
            return StatusCodes.Status.AlreadyDone;
        }
        else
        {
            revert("Invalid state");
        }
    }

    function metaFreezeHash(
            address _owner,
            uint256 _rewardAmount,
            address _rewardTokenAddress)
        public
        view
        returns(bytes32 hash)
    {
        return keccak256(
            abi.encodePacked(
                address(this),
                "metaFreeze",
                _owner,
                _rewardAmount,
                _rewardTokenAddress));
    }

    function getSignatureAddress(bytes32 _hash, bytes memory _signature)
        internal
        pure
        returns (address signer)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_signature.length != 65)
        {
            return address(0);
        }
        
        assembly
        {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        if (v < 27)
        {
            v += 27;
        }
        if (v != 27 && v != 28)
        {
            return address(0);
        }
        else
        {
            return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), v, r, s);
        }
    }

    function payReward(
            SignerState memory _state,
            address _rewardTokenAddress,
            address payable _rewardRecipient,
            uint256 _rewardAmount)
        internal
        returns (uint256)
    {
        if (_rewardAmount > 0)
        {
            require(_state.accessState == ISigner.AccessState.Active, "Cannot pay relay rewards when frozen");

            uint256 octoPay = _rewardAmount.div(10);
            uint rewardPay = _rewardAmount.sub(octoPay);

            IVault vault = IVault(_state.vault);

            // Pay the relayer
            if (_rewardTokenAddress == address(0))
                vault.sendWei(_rewardRecipient, rewardPay);
            else
                vault.sendErc20(_rewardTokenAddress, _rewardRecipient, rewardPay);

            // Pay octobase
            if (octoPay > 0)
            {
                if (_rewardTokenAddress == address(0))
                    vault.sendWei(getOctobase(), octoPay);
                else
                    vault.sendErc20(_rewardTokenAddress, getOctobase(), octoPay);
            }

            return rewardPay;
        }
        else
            return 0;
    }

    // upgrade proposal related methods

    function proposeUpgrade(address _newImplementation)
        external
        onlySelf
        returns (StatusCodes.Status status)
    {
        SignerState memory state = readState();

        setUpgradeProposal(
            block.timestamp.add(7 days),
            _newImplementation,
            state.owner,
            block.timestamp,
            false);

        emit ProposeUpgrade(7 days, _newImplementation);

        return StatusCodes.Status.Success;
    }

    function executeUpgrade()
        external
        returns (StatusCodes.Status status)
    {
        SignerState memory state = readState();

        UpgradeProposal memory proposal = internalGetUpgradeProposal();
        if (!proposal.isExecuted
                && proposal.executionDate <= block.timestamp
                && proposal.implementation != address(0x0)
                && state.accessState == ISigner.AccessState.Active
                && state.owner == proposal.owner)
        {
            proposal.isExecuted = true;
            emit ExecuteUpgrade(msg.sender, proposal.implementation);
            delegate = proposal.implementation;

            internalSetUpgradeProposal(proposal);
            return StatusCodes.Status.Success;
        }
        else
        {
            revert("Proposal is invalid");
        }
    }

    event LogFreezeDate(uint256 freezeDate);
    function checkFreezeInvalidation(
            uint256 _upgradeProposalDate,
            uint256 _upgradeExecutionDate)
        external
        //view
        returns(bool _isValid)
    {
        uint256 freezeIndex = getFreezeIndex();
        emit LogFreezeDate(freezeIndex);

        for(uint256 i = freezeIndex; i > 0; i = i.sub(1))
        {
            uint256 freezeDate = getFreezeDate(i.sub(1));
            emit LogFreezeDate(freezeDate);
            if (_upgradeProposalDate < freezeDate && freezeDate < _upgradeExecutionDate)
                return false;
            if (_upgradeProposalDate >= freezeDate)
                return true;
        }
        return true;
    }

    function octobaseType()
        external
        pure
        returns (uint16 typeId)
    {
        return 1;
    }

    function octobaseTypeVersion()
        external
        pure
        returns (uint32 typeVersion)
    {
        return 1;
    }
}
