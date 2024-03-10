pragma solidity ^0.4.24;

// File: contracts/SafeMath32.sol

library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }

    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn’t hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/AraProxy.sol

/**
 * @title AraProxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract AraProxy {

  bytes32 private constant registryPosition_ = keccak256("io.ara.proxy.registry");
  bytes32 private constant implementationPosition_ = keccak256("io.ara.proxy.implementation");

  modifier restricted() {
    bytes32 registryPosition = registryPosition_;
    address registryAddress;
    assembly {
      registryAddress := sload(registryPosition)
    }
    require(
      msg.sender == registryAddress,
      "Only the AraRegistry can upgrade this proxy."
    );
    _;
  }

  /**
  * @dev the constructor sets the AraRegistry address
  */
  constructor(address _registryAddress, address _implementationAddress) public {
    bytes32 registryPosition = registryPosition_;
    bytes32 implementationPosition = implementationPosition_;
    assembly {
      sstore(registryPosition, _registryAddress)
      sstore(implementationPosition, _implementationAddress)
    }
  }

  function setImplementation(address _newImplementation) public restricted {
    require(_newImplementation != address(0));
    bytes32 implementationPosition = implementationPosition_;
    assembly {
      sstore(implementationPosition, _newImplementation)
    }
  }

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  function () payable public {
    bytes32 implementationPosition = implementationPosition_;
    address _impl;
    assembly {
      _impl := sload(implementationPosition)
    }

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}

// File: contracts/ignored_contracts/Registry.sol

contract Registry {
  address public owner_;
  mapping (bytes32 => address) private proxies_; // contentId (unhashed) => proxy
  mapping (bytes32 => address) private proxyOwners_; // contentId (unhashed) => owner
  mapping (string => address) private versions_; // version => implementation
  mapping (address => string) public proxyImpls_; // proxy => version
  string public latestVersion_;

  event ProxyDeployed(address indexed _owner, bytes32 indexed _contentId, address _address);
  event ProxyUpgraded(bytes32 indexed _contentId, string indexed _version);
  event StandardAdded(string indexed _version, address _address);

  function init(bytes _data) public {
    require(owner_ == address(0), 'Registry has already been initialized.');

    uint256 btsptr;
    address ownerAddr;
    assembly {
      btsptr := add(_data, 32)
      ownerAddr := mload(btsptr)
    }
    owner_ = ownerAddr;
  }

  modifier restricted() {
    require (
      msg.sender == owner_,
      "Sender not authorized."
    );
    _;
  }

  modifier onlyProxyOwner(bytes32 _contentId) {
    require(
      proxyOwners_[_contentId] == msg.sender,
      "Sender not authorized."
    );
    _;
  }

  function getProxyAddress(bytes32 _contentId) public view returns (address) {
    return proxies_[_contentId];
  }

  function getProxyOwner(bytes32 _contentId) public view returns (address) {
    return proxyOwners_[_contentId];
  }

  function getImplementation(string _version) public view returns (address) {
    return versions_[_version];
  }

  function getProxyVersion(bytes32 _contentId) public view returns (string) {
    return proxyImpls_[getProxyAddress(_contentId)];
  }
  
  /**
   * @dev AFS Proxy Factory
   * @param _contentId The unhashed methodless content DID
   * @param _version The implementation version to use with this Proxy
   * @param _data AFS initialization data
   * @return address of the newly deployed Proxy
   */
  function createAFS(bytes32 _contentId, string _version, bytes _data) public {
    require(proxies_[_contentId] == address(0), "Proxy already exists for this content.");
    require(versions_[_version] != address(0), "Version does not exist.");
    AraProxy proxy = new AraProxy(address(this), versions_[_version]);
    proxies_[_contentId] = proxy;
    proxyOwners_[_contentId] = msg.sender;
    upgradeProxyAndCall(_contentId, _version, _data);
    emit ProxyDeployed(msg.sender, _contentId, address(proxy));
  }

  /**
   * @dev Upgrades proxy implementation version
   * @param _contentId The unhashed methodless content DID
   * @param _version The implementation version to upgrade this Proxy to
   */
  function upgradeProxy(bytes32 _contentId, string _version) public onlyProxyOwner(_contentId) {
    require(versions_[_version] != address(0), "Version does not exist.");
    AraProxy proxy = AraProxy(proxies_[_contentId]);
    proxy.setImplementation(versions_[_version]);
    proxyImpls_[proxies_[_contentId]] = _version;
    emit ProxyUpgraded(_contentId, _version);
  }

  /**
   * @dev Upgrades proxy implementation version with initialization
   * @param _contentId The unhashed methodless content DID
   * @param _version The implementation version to upgrade this Proxy to
   * @param _data AFS initialization data
   */
  function upgradeProxyAndCall(bytes32 _contentId, string _version, bytes _data) public onlyProxyOwner(_contentId) {
    require(versions_[_version] != address(0), "Version does not exist.");
    require(keccak256(abi.encodePacked(proxyImpls_[proxy])) != keccak256(abi.encodePacked(_version)), "Proxy is already on this version.");
    AraProxy proxy = AraProxy(proxies_[_contentId]);
    proxy.setImplementation(versions_[_version]);
    proxyImpls_[proxy] = _version;
    require(address(proxy).call(abi.encodeWithSignature("init(bytes)", _data)), "Init failed.");
    emit ProxyUpgraded(_contentId, _version);
  }

  /**
   * @dev Adds a new AFS implementation standard
   * @param _version The implementation version name
   * @param _address The address of the new AFS implementation
   */
  function addStandardVersion(string _version, address _address) public restricted {
    require(versions_[_version] == address(0), "Version already exists.");
    versions_[_version] = _address;
    latestVersion_ = _version;
    emit StandardAdded(_version, _address);
  }
}

// File: contracts/ignored_contracts/Library.sol

contract Library {
  using SafeMath32 for uint32;

  address public owner_;
  mapping (bytes32 => Lib) private libraries_; // hashed methodless owner did => library
  Registry registry_;

  struct Lib {
    uint32 size;
    mapping (uint32 => bytes32) content; // index => contentId (unhashed)
  }

  event AddedToLib(bytes32 indexed _identity, bytes32 indexed _contentId);

  function init(bytes _data) public {
    require(owner_ == address(0), 'Library has already been initialized.');

    uint256 btsptr;
    address ownerAddr;
    address registryAddr;
    assembly {
      btsptr := add(_data, 32)
      ownerAddr := mload(btsptr)
      btsptr := add(_data, 64)
      registryAddr := mload(btsptr)
    }
    owner_ = ownerAddr;
    registry_ = Registry(registryAddr);
  }

  modifier restricted() {
    require (msg.sender == owner_, "Sender not authorized.");
     _;
  }

  modifier fromProxy(bytes32 _contentId) {
    require (msg.sender == registry_.getProxyAddress(_contentId), "Proxy not authorized.");
     _;
  }

  function getLibrarySize(bytes32 _identity) public view returns (uint32 size) {
    return libraries_[_identity].size;
  }

  function getLibraryItem(bytes32 _identity, uint32 _index) public view returns (bytes32 contentId) {
    require (_index < libraries_[_identity].size, "Index does not exist.");
    return libraries_[_identity].content[_index];
  }

  function addLibraryItem(bytes32 _identity, bytes32 _contentId) public fromProxy(_contentId) {
    uint32 libSize = libraries_[_identity].size;
    assert (libraries_[_identity].content[libSize] == bytes32(0));
    libraries_[_identity].content[libSize] = _contentId;
    libraries_[_identity].size++;
    emit AddedToLib(_identity, _contentId);
  }
}
