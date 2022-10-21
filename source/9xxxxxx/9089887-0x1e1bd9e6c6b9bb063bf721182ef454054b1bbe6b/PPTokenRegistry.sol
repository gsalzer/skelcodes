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

interface IPPTokenRegistry {
  event AddToken(address indexed token, address indexed owener, address indexed factory);
  event SetFactory(address factory);
  event SetLockerRegistry(address lockerRegistry);

  function tokenList(uint256 _index) external view returns (address);
  function isValid(address _tokenContract) external view returns (bool);
  function requireValidToken(address _token) external view;
  function addToken(address _privatePropertyToken) external;
  function getAllTokens() external view returns (address[] memory);
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

contract PPTokenRegistry is IPPTokenRegistry, OwnableAndInitializable {

  bytes32 public constant ROLE_TOKEN_REGISTRAR = bytes32("TOKEN_REGISTRAR");

  struct Details {
    bool active;
    address factory;
  }

  IPPGlobalRegistry public globalRegistry;

  address[] public tokenList;

  // Token address => Details
  mapping(address => Details) public tokens;

  modifier onlyFactory() {
    require(
      globalRegistry.getACL().hasRole(msg.sender, ROLE_TOKEN_REGISTRAR),
      "Invalid registrar"
    );

    _;
  }

  function initialize(IPPGlobalRegistry _ppGlobalRegistry) external isInitializer {
    globalRegistry = _ppGlobalRegistry;
  }

  // FACTORY INTERFACE

  function addToken(address _token) external onlyFactory {
    Details storage token = tokens[_token];

    token.active = true;
    token.factory = msg.sender;

    tokenList.push(_token);

    emit AddToken(_token, Ownable(_token).owner(), msg.sender);
  }

  // REQUIRES
  function requireValidToken(address _token) external view {
    require(tokens[_token].active == true, "Token address is invalid");
  }

  // GETTERS

  function isValid(address _token) external view returns (bool) {
    return tokens[_token].active;
  }

  function getAllTokens() external view returns (address[] memory) {
    return tokenList;
  }
}

