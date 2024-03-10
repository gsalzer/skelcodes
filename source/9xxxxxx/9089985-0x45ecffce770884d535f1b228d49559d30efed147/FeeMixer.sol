pragma solidity ^0.5.13;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MockApplication {
  IERC20 galtToken;

  constructor(IERC20 _galtToken) public {
    galtToken = _galtToken;
  }

  function claimProtocolEthFee() external {
    msg.sender.transfer(address(this).balance);
  }

  function claimProtocolGaltFee(bytes32 _applicationId) external {
    galtToken.transfer(msg.sender, galtToken.balanceOf(address(this)));
  }

  function () external payable {
  }
}

library ArraySet {
  struct AddressSet {
    address[] array;
    mapping(address => uint256) map;
    mapping(address => bool) exists;
  }

  struct Bytes32Set {
    bytes32[] array;
    mapping(bytes32 => uint256) map;
    mapping(bytes32 => bool) exists;
  }

  // AddressSet
  function add(AddressSet storage _set, address _v) internal {
    require(_set.exists[_v] == false, "Element already exists");

    _set.map[_v] = _set.array.length;
    _set.exists[_v] = true;
    _set.array.push(_v);
  }

  function addSilent(AddressSet storage _set, address _v) internal returns (bool) {
    if (_set.exists[_v] == true) {
      return false;
    }

    _set.map[_v] = _set.array.length;
    _set.exists[_v] = true;
    _set.array.push(_v);

    return true;
  }

  function remove(AddressSet storage _set, address _v) internal {
    require(_set.array.length > 0, "Array is empty");
    require(_set.exists[_v] == true, "Element doesn't exist");

    _remove(_set, _v);
  }

  function removeSilent(AddressSet storage _set, address _v) internal returns (bool) {
    if (_set.exists[_v] == false) {
      return false;
    }

    _remove(_set, _v);
    return true;
  }

  function _remove(AddressSet storage _set, address _v) internal {
    uint256 lastElementIndex = _set.array.length - 1;
    uint256 currentElementIndex = _set.map[_v];
    address lastElement = _set.array[lastElementIndex];

    _set.array[currentElementIndex] = lastElement;
    delete _set.array[lastElementIndex];

    _set.array.length = _set.array.length - 1;
    delete _set.map[_v];
    delete _set.exists[_v];
    _set.map[lastElement] = currentElementIndex;
  }

  function clear(AddressSet storage _set) internal {
    for (uint256 i = 0; i < _set.array.length; i++) {
      address v = _set.array[i];
      delete _set.map[v];
      _set.exists[v] = false;
    }

    delete _set.array;
  }

  function has(AddressSet storage _set, address _v) internal view returns (bool) {
    return _set.exists[_v];
  }

  function elements(AddressSet storage _set) internal view returns (address[] storage) {
    return _set.array;
  }

  function size(AddressSet storage _set) internal view returns (uint256) {
    return _set.array.length;
  }

  function isEmpty(AddressSet storage _set) internal view returns (bool) {
    return _set.array.length == 0;
  }

  // Bytes32Set
  function add(Bytes32Set storage _set, bytes32 _v) internal {
    require(_set.exists[_v] == false, "Element already exists");

    _add(_set, _v);
  }

  function addSilent(Bytes32Set storage _set, bytes32 _v) internal returns (bool) {
    if (_set.exists[_v] == true) {
      return false;
    }

    _add(_set, _v);

    return true;
  }

  function _add(Bytes32Set storage _set, bytes32 _v) internal {
    _set.map[_v] = _set.array.length;
    _set.exists[_v] = true;
    _set.array.push(_v);
  }

  function remove(Bytes32Set storage _set, bytes32 _v) internal {
    require(_set.array.length > 0, "Array is empty");
    require(_set.exists[_v] == true, "Element doesn't exist");

    _remove(_set, _v);
  }

  function removeSilent(Bytes32Set storage _set, bytes32 _v) internal returns (bool) {
    if (_set.exists[_v] == false) {
      return false;
    }

    _remove(_set, _v);
    return true;
  }

  function _remove(Bytes32Set storage _set, bytes32 _v) internal {
    uint256 lastElementIndex = _set.array.length - 1;
    uint256 currentElementIndex = _set.map[_v];
    bytes32 lastElement = _set.array[lastElementIndex];

    _set.array[currentElementIndex] = lastElement;
    delete _set.array[lastElementIndex];

    _set.array.length = _set.array.length - 1;
    delete _set.map[_v];
    delete _set.exists[_v];
    _set.map[lastElement] = currentElementIndex;
  }

  function clear(Bytes32Set storage _set) internal {
    for (uint256 i = 0; i < _set.array.length; i++) {
      _set.exists[_set.array[i]] = false;
    }

    delete _set.array;
  }

  function has(Bytes32Set storage _set, bytes32 _v) internal view returns (bool) {
    return _set.exists[_v];
  }

  function elements(Bytes32Set storage _set) internal view returns (bytes32[] storage) {
    return _set.array;
  }

  function size(Bytes32Set storage _set) internal view returns (uint256) {
    return _set.array.length;
  }

  function isEmpty(Bytes32Set storage _set) internal view returns (bool) {
    return _set.array.length == 0;
  }

  ///////////////////////////// Uint256Set /////////////////////////////////////////
  struct Uint256Set {
    uint256[] array;
    mapping(uint256 => uint256) map;
    mapping(uint256 => bool) exists;
  }

  function add(Uint256Set storage _set, uint256 _v) internal {
    require(_set.exists[_v] == false, "Element already exists");

    _add(_set, _v);
  }

  function addSilent(Uint256Set storage _set, uint256 _v) internal returns (bool) {
    if (_set.exists[_v] == true) {
      return false;
    }

    _add(_set, _v);

    return true;
  }

  function _add(Uint256Set storage _set, uint256 _v) internal {
    _set.map[_v] = _set.array.length;
    _set.exists[_v] = true;
    _set.array.push(_v);
  }

  function remove(Uint256Set storage _set, uint256 _v) internal {
    require(_set.array.length > 0, "Array is empty");
    require(_set.exists[_v] == true, "Element doesn't exist");

    _remove(_set, _v);
  }

  function removeSilent(Uint256Set storage _set, uint256 _v) internal returns (bool) {
    if (_set.exists[_v] == false) {
      return false;
    }

    _remove(_set, _v);
    return true;
  }

  function _remove(Uint256Set storage _set, uint256 _v) internal {
    uint256 lastElementIndex = _set.array.length - 1;
    uint256 currentElementIndex = _set.map[_v];
    uint256 lastElement = _set.array[lastElementIndex];

    _set.array[currentElementIndex] = lastElement;
    delete _set.array[lastElementIndex];

    _set.array.length = _set.array.length - 1;
    delete _set.map[_v];
    delete _set.exists[_v];
    _set.map[lastElement] = currentElementIndex;
  }

  function clear(Uint256Set storage _set) internal {
    for (uint256 i = 0; i < _set.array.length; i++) {
      _set.exists[_set.array[i]] = false;
    }

    delete _set.array;
  }

  function has(Uint256Set storage _set, uint256 _v) internal view returns (bool) {
    return _set.exists[_v];
  }

  function elements(Uint256Set storage _set) internal view returns (uint256[] storage) {
    return _set.array;
  }

  function size(Uint256Set storage _set) internal view returns (uint256) {
    return _set.array.length;
  }

  function isEmpty(Uint256Set storage _set) internal view returns (bool) {
    return _set.array.length == 0;
  }
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

contract FeeMixer is OwnableAndInitializable {
  using ArraySet for ArraySet.AddressSet;
  using ArraySet for ArraySet.Bytes32Set;

  event AddSource(bytes32 id, address indexed addr);
  event RemoveSource(bytes32 id, address indexed addr);
  event SetDestinations(uint256 count);
  event CallSource(bytes32 indexed id, address indexed sender, bool ok);
  event CallSourceFailed(bytes32 indexed id, address indexed sender, address destination, bytes data);
  event DistributeEthBeneficiary(address beneficiary, uint256 amount);
  event DistributeEth(address sender, uint256 beneficiaries, uint256 passedInAmount, uint256 distributedAmount);
  event DistributeERC20Beneficiary(address beneficiary, uint256 amount);
  event DistributeERC20(address sender, uint256 beneficiaries, uint256 passedInAmount, uint256 distributedAmount);

  struct Source {
    address addr;
    bytes data;
  }

  address[] internal destinationAddresses;
  uint256[] internal destinationShares;

  mapping(bytes32 => Source) internal sourceDetails;
  mapping(address => ArraySet.Bytes32Set) internal sourcesByAddress;

  ArraySet.Bytes32Set internal sources;

  function removeSource(bytes32 _id) external onlyOwner {
    // keep sourceDetails
    sources.remove(_id);
    sourcesByAddress[sourceDetails[_id].addr].remove(_id);

    emit RemoveSource(_id, sourceDetails[_id].addr);
  }

  function initialize(address _newOwner) external isInitializer {
    _transferOwnership(_newOwner);
  }

  function addSource(address _addr, bytes calldata _data) external onlyOwner {
    bytes32 id = keccak256(abi.encode(_addr, _data));

    require(sources.has(id) == false, "Source already exists");

    Source storage s = sourceDetails[id];

    s.addr = _addr;
    s.data = _data;

    sources.add(id);
    sourcesByAddress[_addr].add(id);

    emit AddSource(id, _addr);
  }

  function setDestinations(address[] calldata _addresses, uint256[] calldata _shares) external onlyOwner {
    require(_addresses.length == _shares.length, "Address and share lengths should be equal");

    uint256 total = 0;
    uint256 len = _shares.length;

    for (uint256 i = 0; i < len; i++) {
      total += _shares[i];
    }

    require(total == 100, "Total shares should be equal 100%");

    destinationAddresses = _addresses;
    destinationShares = _shares;

    emit SetDestinations(len);
  }

  // Trigger contract  contract using `call()` to the source
  function callSource(bytes32 _sourceId) external returns (bool) {
    Source storage s = sourceDetails[_sourceId];

    require(sources.has(_sourceId) == true, "Invalid ID");

    address destination = s.addr;
    bytes memory data = s.data;
    uint256 dataLength = s.data.length;

    bool result;

    assembly {
        let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
        let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
        result := call(
            sub(gas, 34710),   // 34710 is the value that solidity is currently emitting
                               // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                               // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
            destination,
            0,                 // Passing in value option doesn't supported
            d,
            dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
            x,
            0                  // Output is ignored, therefore the output size is zero
        )
    }

    emit CallSource(_sourceId, msg.sender, result);

    if (result == false) {
      emit CallSourceFailed(_sourceId, msg.sender, destination, data);
    }

    return result;
  }

  function distributeEth(uint256 _value) external {
    require(_value <= address(this).balance, "Not enough funds");

    uint256 total = 0;
    uint256 reward = 0;
    address payable beneficiary;

    for (uint256 i = 0; i < destinationShares.length; i++) {
      reward = _value * destinationShares[i] / 100;
      beneficiary = address(uint160(destinationAddresses[i]));
      beneficiary.transfer(reward);
      total += reward;

      emit DistributeEthBeneficiary(beneficiary, reward);
    }

    emit DistributeEth(msg.sender, destinationAddresses.length, _value, total);
  }

  function distributeERC20(address _erc20Contract, uint256 _value) external {
    IERC20 token = IERC20(_erc20Contract);

    require(_value <= token.balanceOf(address(this)), "Not enough funds");

    uint256 total = 0;
    uint256 reward = 0;
    address beneficiary;

    for (uint256 i = 0; i < destinationShares.length; i++) {
      reward = _value * destinationShares[i] / 100;
      beneficiary = destinationAddresses[i];
      token.transfer(beneficiary, reward);
      total += reward;

      emit DistributeERC20Beneficiary(beneficiary, reward);
    }

    emit DistributeERC20(msg.sender, destinationAddresses.length, _value, total);
  }

  // GETTERS

  function getSources() external view returns (bytes32[] memory) {
    return sources.elements();
  }

  function getSourceCount() external view returns (uint256) {
    return sources.size();
  }

  function getSourcesByAddress(address _destination) external view returns (bytes32[] memory) {
    return sourcesByAddress[_destination].elements();
  }

  function getSourcesByAddressCount(address _destination) external view returns (uint256) {
    return sourcesByAddress[_destination].size();
  }

  function getSource(
    bytes32 _id
  )
    external
    view
    returns (
      bool active,
      address addr,
      bytes memory data
    )
  {
    Source storage s = sourceDetails[_id];

    active = sources.has(_id);
    addr = s.addr;
    data = s.data;
  }

  function getDestinations() external view returns (address[] memory addresses, uint256[] memory shares) {
    return (destinationAddresses, destinationShares);
  }

  function getDestinationCount() external view returns (uint256) {
    return destinationAddresses.length;
  }

  function () external payable {
  }
}

