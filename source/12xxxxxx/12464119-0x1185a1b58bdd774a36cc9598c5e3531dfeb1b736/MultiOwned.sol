pragma solidity ^0.5.13;

import "./OwnerRole.sol";

contract MultiOwned is OwnerRole {
    uint constant public MAX_OWNER_COUNT = 50;

    struct Transaction {
        bytes data;
        bool executed;
    }

    mapping(bytes32 => Transaction) public transactions;
    mapping(bytes32 => mapping(address => bool)) internal confirmations;
    uint public required;

    event Confirmation(address indexed sender, bytes32 indexed transactionId);
    event Revocation(address indexed sender, bytes32 indexed transactionId);
    event Submission(bytes32 indexed transactionId);
    event Execution(bytes32 indexed transactionId);
    event ExecutionFailure(bytes32 indexed transactionId);
    event Requirement(uint required);

    modifier confirmed(bytes32 _transactionId, address _owner) {
        require(confirmations[_transactionId][_owner]);
        _;
    }

    modifier notConfirmed(bytes32 _transactionId, address _owner) {
        require(!confirmations[_transactionId][_owner]);
        _;
    }

    modifier notExecuted(bytes32 _transactionId) {
        require(!transactions[_transactionId].executed);
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this));
        _;
    }

    modifier transactionExists(bytes32 _transactionId) {
        require(transactions[_transactionId].data.length != 0);
        _;
    }

    modifier validRequirement(uint _ownerCount, uint _required) {
        require(0 < _ownerCount
            && 0 < _required
            && _required <= _ownerCount
            && _ownerCount <= MAX_OWNER_COUNT);
        _;
    }

    constructor(address[] memory _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i = 0; i < _owners.length; ++i) {
            _addOwner(_owners[i]);
        }
        required = _required;
    }

    function addOwner(address _owner)
        public
        onlySelf
        validRequirement(numOwners() + 1, required)
    {
        _addOwner(_owner);
    }

    function addTransaction(bytes memory _data, uint _nonce)
        internal
        returns (bytes32 transactionId)
    {
        if (_nonce == 0) _nonce = block.number;
        transactionId = makeTransactionId(_data, _nonce);
        if (transactions[transactionId].data.length == 0) {
            transactions[transactionId] = Transaction({
                data: _data,
                executed: false
            });
            emit Submission(transactionId);
        }
    }

    function confirmTransaction(bytes32 _transactionId)
        public
        onlyOwner
        transactionExists(_transactionId)
        notConfirmed(_transactionId, msg.sender)
    {
        confirmations[_transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, _transactionId);
        executeTransaction(_transactionId);
    }

    function executeTransaction(bytes32 _transactionId)
        public
        onlyOwner
        confirmed(_transactionId, msg.sender)
        notExecuted(_transactionId)
    {
        if (isConfirmed(_transactionId)) {
            Transaction storage txn = transactions[_transactionId];
            txn.executed = true;
            (bool success,) = address(this).call(txn.data);
            if (success) {
                emit Execution(_transactionId);
            } else {
                emit ExecutionFailure(_transactionId);
                txn.executed = false;
            }
        }
    }

    function removeOwner(address _owner)
        public
        onlySelf
    {
        _removeOwner(_owner);
        if (required > numOwners()) {
            setRequirement(numOwners());
        }
    }

    function renounceOwner()
        public
        validRequirement(numOwners() - 1, required)
    {
        _removeOwner(msg.sender);
    }

    function replaceOwner(address _owner, address _newOwner)
        public
        onlySelf
    {
        _removeOwner(_owner);
        _addOwner(_newOwner);
    }

    function revokeConfirmation(bytes32 _transactionId)
        public
        onlyOwner
        confirmed(_transactionId, msg.sender)
        notExecuted(_transactionId)
    {
        confirmations[_transactionId][msg.sender] = false;
        emit Revocation(msg.sender, _transactionId);
    }

    function setRequirement(uint _required)
        public
        onlySelf
        validRequirement(numOwners(), _required)
    {
        required = _required;
        emit Requirement(_required);
    }

    function submitTransaction(bytes memory _data, uint _nonce)
        public
        returns (bytes32 transactionId)
    {
        transactionId = addTransaction(_data, _nonce);
        confirmTransaction(transactionId);
    }

    function getConfirmationCount(bytes32 _transactionId)
        public
        view
        returns (uint count)
    {
        address[] memory owners = getOwners();
        for (uint i = 0; i < numOwners(); ++i) {
            if (confirmations[_transactionId][owners[i]]) ++count;
        }
    }

    function getConfirmations(bytes32 _transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTmp = new address[](numOwners());
        uint count = 0;
        uint i;
        address[] memory owners = getOwners();
        for (i = 0; i < numOwners(); ++i) {
            if (confirmations[_transactionId][owners[i]]) {
                confirmationsTmp[count] = owners[i];
                ++count;
            }
        }
        _confirmations = new address[](count);
        for (i = 0; i < count; ++i) {
            _confirmations[i] = confirmationsTmp[i];
        }
    }

    function isConfirmed(bytes32 _transactionId)
        public
        view
        returns (bool)
    {
        address[] memory owners = getOwners();
        uint count = 0;
        for (uint i = 0; i < numOwners(); ++i) {
            if (confirmations[_transactionId][owners[i]]) ++count;
            if (count == required) return true;
        }
    }

    function makeTransactionId(bytes memory _data, uint _nonce)
        public
        pure
        returns (bytes32 transactionId)
    {
        transactionId = keccak256(abi.encode(_data, _nonce));
    }
}

