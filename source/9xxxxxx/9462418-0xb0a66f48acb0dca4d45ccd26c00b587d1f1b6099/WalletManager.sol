pragma solidity ^0.5.13;

/// @title iFactory
/// @author Stephane Gosselin (@thegostep) for Numerai Inc
/// @dev Security contact: security@numer.ai
/// @dev Version: 1.3.0
interface iFactory {

    event InstanceCreated(address indexed instance, address indexed creator, bytes callData);

    function create(bytes calldata callData) external returns (address instance);
    function createSalty(bytes calldata callData, bytes32 salt) external returns (address instance);
    function getInitSelector() external view returns (bytes4 initSelector);
    function getInstanceRegistry() external view returns (address instanceRegistry);
    function getTemplate() external view returns (address template);
    function getSaltyInstance(address creator, bytes calldata callData, bytes32 salt) external view returns (address instance, bool validity);
    function getNextNonceInstance(address creator, bytes calldata callData) external view returns (address instance);

    function getInstanceCreator(address instance) external view returns (address creator);
    function getInstanceType() external view returns (bytes4 instanceType);
    function getInstanceCount() external view returns (uint256 count);
    function getInstance(uint256 index) external view returns (address instance);
    function getInstances() external view returns (address[] memory instances);
    function getPaginatedInstances(uint256 startIndex, uint256 endIndex) external view returns (address[] memory instances);
}



/// @title Template
/// @author Stephane Gosselin (@thegostep) for Numerai Inc
/// @dev Security contact: security@numer.ai
/// @dev Version: 1.3.0
/// @notice This module is imported by all template contracts to implement core functionality associated with the factories.
contract Template {

    address private _factory;

    // modifiers

    /// @notice Modifier which only allows to be `DELEGATECALL`ed from within a constructor on initialization of the contract.
    modifier initializeTemplate() {
        // set factory
        _factory = msg.sender;

        // only allow function to be `DELEGATECALL`ed from within a constructor.
        uint32 codeSize;
        assembly { codeSize := extcodesize(address) }
        require(codeSize == 0, "must be called within contract constructor");
        _;
    }

    // view functions

    /// @notice Get the address that created this clone.
    ///         Note, this cannot be trusted because it is possible to frontrun the create function and become the creator.
    /// @return creator address that created this clone.
    function getCreator() public view returns (address creator) {
        // iFactory(...) would revert if _factory address is not actually a factory contract
        return iFactory(_factory).getInstanceCreator(address(this));
    }

    /// @notice Validate if address matches the stored creator.
    /// @param caller address to validate.
    /// @return validity bool true if matching address.
    function isCreator(address caller) internal view returns (bool validity) {
        return (caller == getCreator());
    }

    /// @notice Get the address of the factory for this clone.
    /// @return factory address of the factory.
    function getFactory() public view returns (address factory) {
        return _factory;
    }

}


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


/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <stefan.george@consensys.net>
contract MultiSigWallet is Template {
    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    /*
     *  Constants
     */
    uint256 public constant MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(
            ownerCount <= MAX_OWNER_COUNT &&
                _required <= ownerCount &&
                _required != 0 &&
                ownerCount != 0
        );
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    function initialize(address[] memory _owners, uint256 _required)
        public
        initializeTemplate()
        validRequirement(_owners.length, _required)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner) public onlyWallet ownerExists(owner) {
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length) changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint256 _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) public returns (uint256 transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint256 transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (
                external_call(
                    txn.destination,
                    txn.value,
                    txn.data.length,
                    txn.data
                )
            ) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(
        address destination,
        uint256 value,
        uint256 dataLength,
        bytes memory data
    ) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40) // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas, 34710), // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0 // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) count += 1;
            if (count == required) return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) internal notNull(destination) returns (uint256 transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint256 transactionId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < transactionCount; i++)
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint256 transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    ) public view returns (uint256[] memory _transactionIds) {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++)
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}

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
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an owner and a manager that can be granted exclusive access to
 * specific functions.
 */
contract Manageable is Ownable {
    address private _manager;

    event ManagementTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    constructor () internal Ownable() {
        _manager = _msgSender();
        emit ManagementTransferred(address(0), _manager);
    }

    /**
     * @return the address of the manager.
     */
    function manager() public view returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if called by any account other than the owner or manager.
     */
    modifier onlyManagerOrOwner() {
        require(isManagerOrOwner(), "Manageable: caller is not the manager or owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner or manager of the contract.
     */
    function isManagerOrOwner() public view returns (bool) {
        return (_msgSender() == _manager || isOwner());
    }

    /**
     * @dev Leaves the contract without manager. Owner will need to set a new manager.
     * Can only be called by the current owner or manager.
     */
    function renounceManagement() public onlyManagerOrOwner {
        emit ManagementTransferred(_manager, address(0));
        _manager = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newManager.
     * Can only be called by the current owner.
     * @param newManager The address to transfer management to.
     */
    function transferManagement(address newManager) public onlyOwner {
        require(newManager != address(0), "Manageable: new manager is the zero address");
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }
}



/// @title WalletManager
/// @author Stephane Gosselin (@thegostep) for Numerai Inc
/// @dev Security contact: security@numer.ai
/// @dev Version: 1.3.0
/// @notice This module allows for managing multisig wallets.
// prettier-ignore
contract WalletManager is Manageable {

    address private _walletFactory;

    function getWalletFactory() public view returns (address walletFactory) {
        return _walletFactory;
    }

    constructor(address walletFactory) public {
        _walletFactory = walletFactory;
    }

    /// @dev Allows to create a new wallet.
    /// @return instance address of the clone that was created.
    function create() public onlyManagerOrOwner() returns (address wallet) {
        bytes memory init_calldata = abi.encodeWithSelector(
            iFactory(_walletFactory).getInitSelector(),
            [address(this)], // _owners
            1  // _required
        );
        return iFactory(_walletFactory).create(init_calldata);
    }

    /// @dev Allows to create a new wallet.
    /// @param salt bytes32 unique salt for deterministic address generation
    /// @return instance address of the clone that was created.
    function createSalty(bytes32 salt) public onlyManagerOrOwner() returns (address wallet) {
        bytes memory init_calldata = abi.encodeWithSelector(
            iFactory(_walletFactory).getInitSelector(),
            [address(this)], // _owners
            1  // _required
        );
        return iFactory(_walletFactory).createSalty(init_calldata, salt);
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param wallet Address of wallet.
    /// @param owner Address of new owner.
    function addOwner(address payable wallet, address owner) public onlyManagerOrOwner() {
        MultiSigWallet(wallet).addOwner(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param wallet Address of wallet.
    /// @param owner Address of owner.
    function removeOwner(address payable wallet, address owner) public onlyManagerOrOwner() {
        MultiSigWallet(wallet).removeOwner(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param wallet Address of wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address payable wallet, address owner, address newOwner) public onlyManagerOrOwner() {
        MultiSigWallet(wallet).replaceOwner(owner, newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param wallet Address of wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(address payable wallet, uint256 _required) public onlyManagerOrOwner() {
        MultiSigWallet(wallet).changeRequirement(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param wallet Address of wallet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(
        address payable wallet,
        address destination,
        uint256 value,
        bytes memory data
    ) public onlyManagerOrOwner() returns (uint256 transactionId) {
        return MultiSigWallet(wallet).submitTransaction(destination, value, data);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param wallet Address of wallet.
    /// @param transactionId Transaction ID.
    function confirmTransaction(address payable wallet, uint256 transactionId) public onlyManagerOrOwner() {
        MultiSigWallet(wallet).confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param wallet Address of wallet.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(address payable wallet, uint256 transactionId) public onlyManagerOrOwner() {
        MultiSigWallet(wallet).revokeConfirmation(transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param wallet Address of wallet.
    /// @param transactionId Transaction ID.
    function executeTransaction(address payable wallet, uint256 transactionId) public onlyManagerOrOwner() {
        MultiSigWallet(wallet).executeTransaction(transactionId);
    }
}

