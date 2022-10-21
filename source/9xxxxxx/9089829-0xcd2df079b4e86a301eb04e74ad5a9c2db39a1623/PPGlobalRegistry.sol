pragma solidity ^0.5.13;

interface IACL {
  function setRole(bytes32 _role, address _candidate, bool _allow) external;
  function hasRole(address _candidate, bytes32 _role) external view returns (bool);
}

interface IPPGlobalRegistry {
  function setContract(bytes32 _key, address _value) external;

  // GETTERS
  function getContract(bytes32 _key) external view returns (address);
  function getACL() external view returns (IACL);
  function getGaltTokenAddress() external view returns (address);
  function getPPTokenRegistryAddress() external view returns (address);
  function getPPLockerRegistryAddress() external view returns (address);
  function getPPMarketAddress() external view returns (address);
}

contract Initializable {

  /**
   * @dev Indicates if the contract has been initialized.
   */
  bool public initialized;

  /**
   * @dev Modifier to use in the initialization function of a contract.
   */
  modifier isInitializer() {
    require(!initialized, "Contract instance has already been initialized");
    _;
    initialized = true;
  }
}

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

contract OwnableAndInitializable is Ownable, Initializable {

  /**
   * @dev Modifier to use in the initialization function of a contract.
   */
  modifier isInitializer() {
    require(!initialized, "Contract instance has already been initialized");
    _;
    initialized = true;
    _transferOwnership(tx.origin);
  }

  /**
   * @dev Modifier to use in the initialization function of a contract. Allow a custom owner setup;
   */
  modifier initializeWithOwner(address _owner) {
    require(!initialized, "Contract instance has already been initialized");
    _;
    initialized = true;
    _transferOwnership(_owner);
  }
}

contract PPGlobalRegistry is IPPGlobalRegistry, OwnableAndInitializable {
  // solium-disable-next-line mixedcase
  address internal constant ZERO_ADDRESS = address(0);

  bytes32 public constant PPGR_ACL = bytes32("ACL");
  bytes32 public constant PPGR_GALT_TOKEN = bytes32("galt_token");
  bytes32 public constant PPGR_LOCKER_REGISTRY = bytes32("locker_registry");
  bytes32 public constant PPGR_TOKEN_REGISTRY = bytes32("token_registry");
  bytes32 public constant PPGR_MARKET = bytes32("market");

  event SetContract(bytes32 indexed key, address addr);

  mapping(bytes32 => address) internal contracts;

  function initialize() public isInitializer {
  }

  function setContract(bytes32 _key, address _value) external onlyOwner {
    contracts[_key] = _value;

    emit SetContract(_key, _value);
  }

  // GETTERS
  function getContract(bytes32 _key) external view returns (address) {
    return contracts[_key];
  }

  function getACL() external view returns (IACL) {
    require(contracts[PPGR_ACL] != ZERO_ADDRESS, "PPGR: ACL not set");
    return IACL(contracts[PPGR_ACL]);
  }

  function getGaltTokenAddress() external view returns (address) {
    require(contracts[PPGR_GALT_TOKEN] != ZERO_ADDRESS, "PPGR: GALT_TOKEN not set");
    return contracts[PPGR_GALT_TOKEN];
  }

  function getPPTokenRegistryAddress() external view returns (address) {
    require(contracts[PPGR_TOKEN_REGISTRY] != ZERO_ADDRESS, "PPGR: TOKEN_REGISTRY not set");
    return contracts[PPGR_TOKEN_REGISTRY];
  }

  function getPPLockerRegistryAddress() external view returns (address) {
    require(contracts[PPGR_LOCKER_REGISTRY] != ZERO_ADDRESS, "PPGR: LOCKER_REGISTRY not set");
    return contracts[PPGR_LOCKER_REGISTRY];
  }

  function getPPMarketAddress() external view returns (address) {
    require(contracts[PPGR_MARKET] != ZERO_ADDRESS, "PPGR: MARKET not set");
    return contracts[PPGR_MARKET];
  }
}

