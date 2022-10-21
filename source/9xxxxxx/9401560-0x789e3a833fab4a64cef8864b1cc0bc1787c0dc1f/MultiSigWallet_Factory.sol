pragma solidity ^0.5.13;


/// @title Spawn
/// @author 0age (@0age) for Numerai Inc
/// @dev Security contact: security@numer.ai
/// @dev Version: 1.3.0
/// @notice This contract provides creation code that is used by Spawner in order
/// to initialize and deploy eip-1167 minimal proxies for a given logic contract.
contract Spawn {
  constructor(
    address logicContract,
    bytes memory initializationCalldata
  ) public payable {
    // delegatecall into the logic contract to perform initialization.
    (bool ok, ) = logicContract.delegatecall(initializationCalldata);
    if (!ok) {
      // pass along failure message from delegatecall and revert.
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }

    // place eip-1167 runtime code in memory.
    bytes memory runtimeCode = abi.encodePacked(
      bytes10(0x363d3d373d3d3d363d73),
      logicContract,
      bytes15(0x5af43d82803e903d91602b57fd5bf3)
    );

    // return eip-1167 code to write it to spawned contract runtime.
    assembly {
      return(add(0x20, runtimeCode), 45) // eip-1167 runtime code, length
    }
  }
}

/// @title Spawner
/// @author 0age (@0age) and Stephane Gosselin (@thegostep) for Numerai Inc
/// @dev Security contact: security@numer.ai
/// @dev Version: 1.3.0
/// @notice This contract spawns and initializes eip-1167 minimal proxies that
/// point to existing logic contracts. The logic contracts need to have an
/// initializer function that should only callable when no contract exists at
/// their current address (i.e. it is being `DELEGATECALL`ed from a constructor).
contract Spawner {
  
  /// @notice Internal function for spawning an eip-1167 minimal proxy using `CREATE2`.
  /// @param creator address The address of the account creating the proxy.
  /// @param logicContract address The address of the logic contract.
  /// @param initializationCalldata bytes The calldata that will be supplied to
  /// the `DELEGATECALL` from the spawned contract to the logic contract during
  /// contract creation.
  /// @return The address of the newly-spawned contract.
  function _spawn(
    address creator,
    address logicContract,
    bytes memory initializationCalldata
  ) internal returns (address spawnedContract) {

    // get instance code and hash

    bytes memory initCode;
    bytes32 initCodeHash;
    (initCode, initCodeHash) = _getInitCodeAndHash(logicContract, initializationCalldata);

    // get valid create2 target

    (address target, bytes32 safeSalt) = _getNextNonceTargetWithInitCodeHash(creator, initCodeHash);

    // spawn create2 instance and validate

    return _executeSpawnCreate2(initCode, safeSalt, target);
  }

  /// @notice Internal function for spawning an eip-1167 minimal proxy using `CREATE2`.
  /// @param creator address The address of the account creating the proxy.
  /// @param logicContract address The address of the logic contract.
  /// @param initializationCalldata bytes The calldata that will be supplied to
  /// the `DELEGATECALL` from the spawned contract to the logic contract during
  /// contract creation.
  /// @param salt bytes32 A user defined salt.
  /// @return The address of the newly-spawned contract.
  function _spawnSalty(
    address creator,
    address logicContract,
    bytes memory initializationCalldata,
    bytes32 salt
  ) internal returns (address spawnedContract) {

    // get instance code and hash

    bytes memory initCode;
    bytes32 initCodeHash;
    (initCode, initCodeHash) = _getInitCodeAndHash(logicContract, initializationCalldata);

    // get valid create2 target

    (address target, bytes32 safeSalt, bool validity) = _getSaltyTargetWithInitCodeHash(creator, initCodeHash, salt);
    require(validity, "contract already deployed with supplied salt");

    // spawn create2 instance and validate

    return _executeSpawnCreate2(initCode, safeSalt, target);
  }

  /// @notice Private function for spawning an eip-1167 minimal proxy using `CREATE2`.
  /// Reverts with appropriate error string if deployment is unsuccessful.
  /// @param initCode bytes The spawner code and initialization calldata.
  /// @param safeSalt bytes32 A valid salt hashed with creator address.
  /// @param target address The expected address of the proxy.
  /// @return The address of the newly-spawned contract.
  function _executeSpawnCreate2(bytes memory initCode, bytes32 safeSalt, address target) private returns (address spawnedContract) {
    assembly {
      let encoded_data := add(0x20, initCode) // load initialization code.
      let encoded_size := mload(initCode)     // load the init code's length.
      spawnedContract := create2(             // call `CREATE2` w/ 4 arguments.
        callvalue,                            // forward any supplied endowment.
        encoded_data,                         // pass in initialization code.
        encoded_size,                         // pass in init code's length.
        safeSalt                              // pass in the salt value.
      )

      // pass along failure message from failed contract deployment and revert.
      if iszero(spawnedContract) {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }

    // validate spawned instance matches target
    require(spawnedContract == target, "attempted deployment to unexpected address");

    // explicit return
    return spawnedContract;
  }

  /// @notice Internal view function for finding the expected address of the standard
  /// eip-1167 minimal proxy created using `CREATE2` with a given logic contract,
  /// salt, and initialization calldata payload.
  /// @param creator address The address of the account creating the proxy.
  /// @param logicContract address The address of the logic contract.
  /// @param initializationCalldata bytes The calldata that will be supplied to
  /// the `DELEGATECALL` from the spawned contract to the logic contract during
  /// contract creation.
  /// @param salt bytes32 A user defined salt.
  /// @return target address The address of the newly-spawned contract.
  /// @return validity bool True if the `target` is available.
  function _getSaltyTarget(
    address creator,
    address logicContract,
    bytes memory initializationCalldata,
    bytes32 salt
  ) internal view returns (address target, bool validity) {

    // get initialization code

    bytes32 initCodeHash;
    ( , initCodeHash) = _getInitCodeAndHash(logicContract, initializationCalldata);

    // get valid target

    (target, , validity) = _getSaltyTargetWithInitCodeHash(creator, initCodeHash, salt);

    // explicit return
    return (target, validity);
  }

  /// @notice Internal view function for finding the expected address of the standard
  /// eip-1167 minimal proxy created using `CREATE2` with a given initCodeHash, and salt.
  /// @param creator address The address of the account creating the proxy.
  /// @param initCodeHash bytes32 The hash of initCode.
  /// @param salt bytes32 A user defined salt.
  /// @return target address The address of the newly-spawned contract.
  /// @return safeSalt bytes32 A safe salt. Must include the msg.sender address for front-running protection.
  /// @return validity bool True if the `target` is available.
  function _getSaltyTargetWithInitCodeHash(
    address creator,
    bytes32 initCodeHash,
    bytes32 salt
  ) private view returns (address target, bytes32 safeSalt, bool validity) {
    // get safeSalt from input
    safeSalt = keccak256(abi.encodePacked(creator, salt));

    // get expected target
    target = _computeTargetWithCodeHash(initCodeHash, safeSalt);

    // get target validity
    validity = _getTargetValidity(target);

    // explicit return
    return (target, safeSalt, validity);
  }

  /// @notice Internal view function for finding the expected address of the standard
  /// eip-1167 minimal proxy created using `CREATE2` with a given logic contract,
  /// nonce, and initialization calldata payload.
  /// @param creator address The address of the account creating the proxy.
  /// @param logicContract address The address of the logic contract.
  /// @param initializationCalldata bytes The calldata that will be supplied to
  /// the `DELEGATECALL` from the spawned contract to the logic contract during
  /// contract creation.
  /// @return target address The address of the newly-spawned contract.
  function _getNextNonceTarget(
    address creator,
    address logicContract,
    bytes memory initializationCalldata
  ) internal view returns (address target) {

    // get initialization code

    bytes32 initCodeHash;
    ( , initCodeHash) = _getInitCodeAndHash(logicContract, initializationCalldata);

    // get valid target

    (target, ) = _getNextNonceTargetWithInitCodeHash(creator, initCodeHash);

    // explicit return
    return target;
  }

  /// @notice Internal view function for finding the expected address of the standard
  /// eip-1167 minimal proxy created using `CREATE2` with a given initCodeHash, and nonce.
  /// @param creator address The address of the account creating the proxy.
  /// @param initCodeHash bytes32 The hash of initCode.
  /// @return target address The address of the newly-spawned contract.
  /// @return safeSalt bytes32 A safe salt. Must include the msg.sender address for front-running protection.
  function _getNextNonceTargetWithInitCodeHash(
    address creator,
    bytes32 initCodeHash
  ) private view returns (address target, bytes32 safeSalt) {
    // set the initial nonce to be provided when constructing the salt.
    uint256 nonce = 0;

    while (true) {
      // get safeSalt from nonce
      safeSalt = keccak256(abi.encodePacked(creator, nonce));

      // get expected target
      target = _computeTargetWithCodeHash(initCodeHash, safeSalt);

      // validate no contract already deployed to the target address.
      // exit the loop if no contract is deployed to the target address.
      // otherwise, increment the nonce and derive a new salt.
      if (_getTargetValidity(target))
        break;
      else
        nonce++;
    }
    
    // explicit return
    return (target, safeSalt);
  }

  /// @notice Private pure function for obtaining the initCode and the initCodeHash of `logicContract` and `initializationCalldata`.
  /// @param logicContract address The address of the logic contract.
  /// @param initializationCalldata bytes The calldata that will be supplied to
  /// the `DELEGATECALL` from the spawned contract to the logic contract during
  /// contract creation.
  /// @return initCode bytes The spawner code and initialization calldata.
  /// @return initCodeHash bytes32 The hash of initCode.
  function _getInitCodeAndHash(
    address logicContract,
    bytes memory initializationCalldata
  ) private pure returns (bytes memory initCode, bytes32 initCodeHash) {
    // place creation code and constructor args of contract to spawn in memory.
    initCode = abi.encodePacked(
      type(Spawn).creationCode,
      abi.encode(logicContract, initializationCalldata)
    );

    // get the keccak256 hash of the init code for address derivation.
    initCodeHash = keccak256(initCode);

    // explicit return
    return (initCode, initCodeHash);
  }
  
  /// @notice Private view function for finding the expected address of the standard
  /// eip-1167 minimal proxy created using `CREATE2` with a given logic contract,
  /// salt, and initialization calldata payload.
  /// @param initCodeHash bytes32 The hash of initCode.
  /// @param safeSalt bytes32 A safe salt. Must include the msg.sender address for front-running protection.
  /// @return The address of the proxy contract with the given parameters.
  function _computeTargetWithCodeHash(
    bytes32 initCodeHash,
    bytes32 safeSalt
  ) private view returns (address target) {
    return address(    // derive the target deployment address.
      uint160(                   // downcast to match the address type.
        uint256(                 // cast to uint to truncate upper digits.
          keccak256(             // compute CREATE2 hash using 4 inputs.
            abi.encodePacked(    // pack all inputs to the hash together.
              bytes1(0xff),      // pass in the control character.
              address(this),     // pass in the address of this contract.
              safeSalt,          // pass in the safeSalt from above.
              initCodeHash       // pass in hash of contract creation code.
            )
          )
        )
      )
    );
  }

  /// @notice Private view function to validate if the `target` address is an available deployment address.
  /// @param target address The address to validate.
  /// @return validity bool True if the `target` is available.
  function _getTargetValidity(address target) private view returns (bool validity) {
    // validate no contract already deployed to the target address.
    uint256 codeSize;
    assembly { codeSize := extcodesize(target) }
    return codeSize == 0;
  }
}



/// @title iRegistry
/// @author Stephane Gosselin (@thegostep) for Numerai Inc
/// @dev Security contact: security@numer.ai
/// @dev Version: 1.3.0
interface iRegistry {

    enum FactoryStatus { Unregistered, Registered, Retired }

    event FactoryAdded(address owner, address factory, uint256 factoryID, bytes extraData);
    event FactoryRetired(address owner, address factory, uint256 factoryID);
    event InstanceRegistered(address instance, uint256 instanceIndex, address indexed creator, address indexed factory, uint256 indexed factoryID);

    // factory state functions

    function addFactory(address factory, bytes calldata extraData ) external;
    function retireFactory(address factory) external;

    // factory view functions

    function getFactoryCount() external view returns (uint256 count);
    function getFactoryStatus(address factory) external view returns (FactoryStatus status);
    function getFactoryID(address factory) external view returns (uint16 factoryID);
    function getFactoryData(address factory) external view returns (bytes memory extraData);
    function getFactoryAddress(uint16 factoryID) external view returns (address factory);
    function getFactory(address factory) external view returns (FactoryStatus state, uint16 factoryID, bytes memory extraData);
    function getFactories() external view returns (address[] memory factories);
    function getPaginatedFactories(uint256 startIndex, uint256 endIndex) external view returns (address[] memory factories);

    // instance state functions

    function register(address instance, address creator, uint80 extraData) external;

    // instance view functions

    function getInstanceType() external view returns (bytes4 instanceType);
    function getInstanceCount() external view returns (uint256 count);
    function getInstance(uint256 index) external view returns (address instance);
    function getInstances() external view returns (address[] memory instances);
    function getPaginatedInstances(uint256 startIndex, uint256 endIndex) external view returns (address[] memory instances);
}


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




/// @title Factory
/// @author Stephane Gosselin (@thegostep) for Numerai Inc
/// @dev Security contact: security@numer.ai
/// @dev Version: 1.3.0
/// @notice The factory contract implements a standard interface for creating EIP-1167 clones of a given template contract.
///         The create functions accept abi-encoded calldata used to initialize the spawned templates.
contract Factory is Spawner, iFactory {
    address[] private _instances;
    mapping(address => address) private _instanceCreator;

    /* NOTE: The following items can be hardcoded as constant to save ~200 gas/create */
    address private _templateContract;
    bytes4 private _initSelector;
    address private _instanceRegistry;
    bytes4 private _instanceType;

    event InstanceCreated(
        address indexed instance,
        address indexed creator,
        bytes callData
    );

    /// @notice Constructior
    /// @param instanceRegistry address of the registry where all clones are registered.
    /// @param templateContract address of the template used for making clones.
    /// @param instanceType bytes4 identifier for the type of the factory. This must match the type of the registry.
    /// @param initSelector bytes4 selector for the template initialize function.
    function _initialize(
        address instanceRegistry,
        address templateContract,
        bytes4 instanceType,
        bytes4 initSelector
    ) internal {
        // set instance registry
        _instanceRegistry = instanceRegistry;
        // set logic contract
        _templateContract = templateContract;
        // set initSelector
        _initSelector = initSelector;
        // validate correct instance registry
        // require(instanceType == iRegistry(instanceRegistry).getInstanceType(), 'incorrect instance type');
        // set instanceType
        _instanceType = instanceType;
    }

    // IFactory methods

    /// @notice Create clone of the template using a nonce.
    ///         The nonce is unique for clones with the same initialization calldata.
    ///         The nonce can be used to determine the address of the clone before creation.
    ///         The callData must be prepended by the function selector of the template's initialize function and include all parameters.
    /// @param callData bytes blob of abi-encoded calldata used to initialize the template.
    /// @return instance address of the clone that was created.
    function create(bytes memory callData) public returns (address instance) {
        // deploy new contract: initialize it & write minimal proxy to runtime.
        instance = Spawner._spawn(msg.sender, getTemplate(), callData);

        _createHelper(instance, callData);

        return instance;
    }

    /// @notice Create clone of the template using a salt.
    ///         The salt must be unique for clones with the same initialization calldata.
    ///         The salt can be used to determine the address of the clone before creation.
    ///         The callData must be prepended by the function selector of the template's initialize function and include all parameters.
    /// @param callData bytes blob of abi-encoded calldata used to initialize the template.
    /// @return instance address of the clone that was created.
    function createSalty(bytes memory callData, bytes32 salt)
        public
        returns (address instance)
    {
        // deploy new contract: initialize it & write minimal proxy to runtime.
        instance = Spawner._spawnSalty(
            msg.sender,
            getTemplate(),
            callData,
            salt
        );

        _createHelper(instance, callData);

        return instance;
    }

    /// @notice Private function to help with the creation of the clone.
    ///         Stores the address of the clone in this contract.
    ///         Stores the creator of the clone in this contract.
    ///         Registers the address of the clone in the registry. Fails if the factory is deprecated.
    ///         Emits standard InstanceCreated event
    /// @param instance address The address of the clone that was created.
    /// @param callData bytes The initialization calldata to use on the clone.
    function _createHelper(address instance, bytes memory callData) private {
        // add the instance to the array
        _instances.push(instance);
        // set instance creator
        _instanceCreator[instance] = msg.sender;
        // add the instance to the instance registry
        // iRegistry(getInstanceRegistry()).register(instance, msg.sender, uint80(0));
        // emit event
        emit InstanceCreated(instance, msg.sender, callData);
    }

    /// @notice Get the address of an instance for a given salt
    function getSaltyInstance(
        address creator,
        bytes memory callData,
        bytes32 salt
    ) public view returns (address instance, bool validity) {
        return Spawner._getSaltyTarget(creator, getTemplate(), callData, salt);
    }

    function getNextNonceInstance(address creator, bytes memory callData)
        public
        view
        returns (address target)
    {
        return Spawner._getNextNonceTarget(creator, getTemplate(), callData);
    }

    function getInstanceCreator(address instance)
        public
        view
        returns (address creator)
    {
        return _instanceCreator[instance];
    }

    function getInstanceType() public view returns (bytes4 instanceType) {
        return _instanceType;
    }

    function getInitSelector() public view returns (bytes4 initSelector) {
        return _initSelector;
    }

    function getInstanceRegistry()
        public
        view
        returns (address instanceRegistry)
    {
        return _instanceRegistry;
    }

    function getTemplate() public view returns (address template) {
        return _templateContract;
    }

    function getInstanceCount() public view returns (uint256 count) {
        return _instances.length;
    }

    function getInstance(uint256 index) public view returns (address instance) {
        require(index < _instances.length, 'index out of range');
        return _instances[index];
    }

    function getInstances() public view returns (address[] memory instances) {
        return _instances;
    }

    // Note: startIndex is inclusive, endIndex exclusive
    function getPaginatedInstances(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (address[] memory instances)
    {
        require(startIndex < endIndex, 'startIndex must be less than endIndex');
        require(endIndex <= _instances.length, 'end index out of range');

        // initialize fixed size memory array
        address[] memory range = new address[](endIndex - startIndex);

        // Populate array with addresses in range
        for (uint256 i = startIndex; i < endIndex; i++) {
            range[i - startIndex] = _instances[i];
        }

        // return array of addresses
        return range;
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



contract MultiSigWallet_Factory is Factory {
    constructor(address instanceRegistry, address templateContract) public {
        MultiSigWallet template;

        // set instance type
        bytes4 instanceType = bytes4(keccak256(bytes('Wallet')));
        // set initSelector
        bytes4 initSelector = template.initialize.selector;
        // initialize factory params
        Factory._initialize(
            instanceRegistry,
            templateContract,
            instanceType,
            initSelector
        );
    }
}

