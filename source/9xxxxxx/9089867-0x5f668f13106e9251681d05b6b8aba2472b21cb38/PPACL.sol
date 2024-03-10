pragma solidity ^0.5.13;

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

interface IACL {
  function setRole(bytes32 _role, address _candidate, bool _allow) external;
  function hasRole(address _candidate, bytes32 _role) external view returns (bool);
}

contract ACL is IACL, OwnableAndInitializable {
  event SetRole(bytes32 indexed role, address indexed candidate, bool allowed);

  // Mapping (roleName => (address => isAllowed))
  mapping(bytes32 => mapping(address => bool)) _roles;

  function initialize() external isInitializer {
  }

  /**
   * @notice Sets role permissions.
   *
   * @param _role bytes32 encoded role name
   * @param _candidate address
   * @param _allow true to enable, false to disable
   */
  function setRole(bytes32 _role, address _candidate, bool _allow) external onlyOwner {
    _roles[_role][_candidate] = _allow;
    emit SetRole(_role, _candidate, _allow);
  }

  /**
   * @notice Checks if a candidate has a role.
   *
   * @param _candidate address
   * @param _role bytes32 encoded role name
   * @return bool whether a user has the role assigned or not
   */
  function hasRole(address _candidate, bytes32 _role) external view returns (bool) {
    return _roles[_role][_candidate];
  }
}

contract PPACL is ACL {
  // ಠ_ಠ
}

