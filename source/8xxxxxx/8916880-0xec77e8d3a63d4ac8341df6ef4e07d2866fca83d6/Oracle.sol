// File: chainlink/evm/contracts/vendor/Ownable.sol

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: chainlink/evm/contracts/vendor/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: chainlink/evm/contracts/interfaces/ChainlinkRequestInterface.sol

pragma solidity 0.4.24;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 payment,
    bytes32 id,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 version,
    bytes data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// File: chainlink/evm/contracts/interfaces/OracleInterface.sol

pragma solidity 0.4.24;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);
  function getAuthorizationStatus(address node) external view returns (bool);
  function setFulfillmentPermission(address node, bool allowed) external;
  function withdraw(address recipient, uint256 amount) external;
  function withdrawable() external view returns (uint256);
}

// File: chainlink/evm/contracts/interfaces/LinkTokenInterface.sol

pragma solidity 0.4.24;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external returns (uint256 balance);
  function decimals() external returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external returns (string tokenName);
  function symbol() external returns (string tokenSymbol);
  function totalSupply() external returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// File: chainlink/evm/contracts/Oracle.sol

pragma solidity 0.4.24;






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

contract IGST2 is IERC20 {

    function freeUpTo(uint256 value) external returns (uint256 freed);

    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);

    function balanceOf(address who) external view returns (uint256);
}

/**
 * @title The Chainlink Oracle contract
 * @notice Node operators can deploy this contract to fulfill requests sent to them
 */
contract Oracle is ChainlinkRequestInterface, OracleInterface, Ownable {
  using SafeMath for uint256;
  
  IGST2 public gasToken;
  address public gasTokenOwner;

  uint256 constant public EXPIRY_TIME = 5 minutes;
  uint256 constant private MINIMUM_CONSUMER_GAS_LIMIT = 400000;
  // We initialize fields to 1 instead of 0 so that the first invocation
  // does not cost more gas.
  uint256 constant private ONE_FOR_CONSISTENT_GAS_COST = 1;
  uint256 constant private SELECTOR_LENGTH = 4;
  uint256 constant private EXPECTED_REQUEST_WORDS = 2;
  uint256 constant private MINIMUM_REQUEST_LENGTH = SELECTOR_LENGTH + (32 * EXPECTED_REQUEST_WORDS);

  LinkTokenInterface internal LinkToken;
  mapping(bytes32 => bytes32) private commitments;
  mapping(address => bool) private authorizedNodes;
  uint256 private withdrawableTokens = ONE_FOR_CONSISTENT_GAS_COST;

  event OracleRequest(
    bytes32 indexed specId,
    address requester,
    bytes32 requestId,
    uint256 payment,
    address callbackAddr,
    bytes4 callbackFunctionId,
    uint256 cancelExpiration,
    uint256 dataVersion,
    bytes data
  );

  event CancelOracleRequest(
    bytes32 indexed requestId
  );

  /**
   * @notice Deploy with the address of the LINK token
   * @dev Sets the LinkToken address for the imported LinkTokenInterface
   * @param _link The address of the LINK token
   */
  constructor(address _link, IGST2 _gasToken, address _gasTokenOwner) public Ownable() {
    gasToken = _gasToken;
    gasTokenOwner = _gasTokenOwner;
    LinkToken = LinkTokenInterface(_link); // external but already deployed and unalterable
  }

  /**
   * @notice Called when LINK is sent to the contract via `transferAndCall`
   * @dev The data payload's first 2 words will be overwritten by the `_sender` and `_amount`
   * values to ensure correctness. Calls oracleRequest.
   * @param _sender Address of the sender
   * @param _amount Amount of LINK sent (specified in wei)
   * @param _data Payload of the transaction
   */
  function onTokenTransfer(
    address _sender,
    uint256 _amount,
    bytes _data
  )
    public
    onlyLINK
    validRequestLength(_data)
    permittedFunctionsForLINK(_data)
  {
    assembly { // solhint-disable-line no-inline-assembly
      mstore(add(_data, 36), _sender) // ensure correct sender is passed
      mstore(add(_data, 68), _amount) // ensure correct amount is passed
    }
    // solhint-disable-next-line avoid-low-level-calls
    require(address(this).delegatecall(_data), "Unable to create request"); // calls oracleRequest
  }

  /**
   * @notice Creates the Chainlink request
   * @dev Stores the hash of the params as the on-chain commitment for the request.
   * Emits OracleRequest event for the Chainlink node to detect.
   * @param _sender The sender of the request
   * @param _payment The amount of payment given (specified in wei)
   * @param _specId The Job Specification ID
   * @param _callbackAddress The callback address for the response
   * @param _callbackFunctionId The callback function ID for the response
   * @param _nonce The nonce sent by the requester
   * @param _dataVersion The specified data version
   * @param _data The CBOR payload of the request
   */
  function oracleRequest(
    address _sender,
    uint256 _payment,
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionId,
    uint256 _nonce,
    uint256 _dataVersion,
    bytes _data
  )
    external
    onlyLINK
    checkCallbackAddress(_callbackAddress)
  {    
    bytes32 requestId = keccak256(abi.encodePacked(_sender, _nonce));
    require(commitments[requestId] == 0, "Must use a unique ID");
    // solhint-disable-next-line not-rely-on-time
    uint256 expiration = now.add(EXPIRY_TIME);

    commitments[requestId] = keccak256(
      abi.encodePacked(
        _payment,
        _callbackAddress,
        _callbackFunctionId,
        expiration
      )
    );

    emit OracleRequest(
      _specId,
      _sender,
      requestId,
      _payment,
      _callbackAddress,
      _callbackFunctionId,
      expiration,
      _dataVersion,
      _data);
  }

  /**
   * @notice Called by the Chainlink node to fulfill requests
   * @dev Given params must hash back to the commitment stored from `oracleRequest`.
   * Will call the callback address' callback function without bubbling up error
   * checking in a `require` so that the node can get paid.
   * @param _requestId The fulfillment request ID that must match the requester's
   * @param _payment The payment amount that will be released for the oracle (specified in wei)
   * @param _callbackAddress The callback address to call for fulfillment
   * @param _callbackFunctionId The callback function ID to use for fulfillment
   * @param _expiration The expiration that the node should respond by before the requester can cancel
   * @param _data The data to return to the consuming contract
   * @return Status if the external call was successful
   */
  function fulfillOracleRequest(
    bytes32 _requestId,
    uint256 _payment,
    address _callbackAddress,
    bytes4 _callbackFunctionId,
    uint256 _expiration,
    bytes32 _data
  )
    external
    onlyAuthorizedNode
    isValidRequest(_requestId)
    returns (bool)
  {
    uint256 gasProvided = gasleft();
  
    bytes32 paramsHash = keccak256(
      abi.encodePacked(
        _payment,
        _callbackAddress,
        _callbackFunctionId,
        _expiration
      )
    );
    require(commitments[_requestId] == paramsHash, "Params do not match request ID");
    withdrawableTokens = withdrawableTokens.add(_payment);
    delete commitments[_requestId];
    require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");
    // All updates to the oracle's fulfillment should come before calling the
    // callback(addr+functionId) as it is untrusted.
    // See: https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern
    bool result = _callbackAddress.call(_callbackFunctionId, _requestId, _data); // solhint-disable-line avoid-low-level-calls
    burnGasToken(gasProvided.sub(gasleft()));
    return result;
  }

  /**
   * @notice Use this to check if a node is authorized for fulfilling requests
   * @param _node The address of the Chainlink node
   * @return The authorization status of the node
   */
  function getAuthorizationStatus(address _node) external view returns (bool) {
    return authorizedNodes[_node];
  }

  /**
   * @notice Sets the fulfillment permission for a given node. Use `true` to allow, `false` to disallow.
   * @param _node The address of the Chainlink node
   * @param _allowed Bool value to determine if the node can fulfill requests
   */
  function setFulfillmentPermission(address _node, bool _allowed) external onlyOwner {
    authorizedNodes[_node] = _allowed;
  }

  /**
   * @notice Allows the node operator to withdraw earned LINK to a given address
   * @dev The owner of the contract can be another wallet and does not have to be a Chainlink node
   * @param _recipient The address to send the LINK token to
   * @param _amount The amount to send (specified in wei)
   */
  function withdraw(address _recipient, uint256 _amount)
    external
    onlyOwner
    hasAvailableFunds(_amount)
  {
    withdrawableTokens = withdrawableTokens.sub(_amount);
    assert(LinkToken.transfer(_recipient, _amount));
  }

  /**
   * @notice Displays the amount of LINK that is available for the node operator to withdraw
   * @dev We use `ONE_FOR_CONSISTENT_GAS_COST` in place of 0 in storage
   * @return The amount of withdrawable LINK on the contract
   */
  function withdrawable() external view onlyOwner returns (uint256) {
    return withdrawableTokens.sub(ONE_FOR_CONSISTENT_GAS_COST);
  }

  /**
   * @notice Allows requesters to cancel requests sent to this oracle contract. Will transfer the LINK
   * sent for the request back to the requester's address.
   * @dev Given params must hash to a commitment stored on the contract in order for the request to be valid
   * Emits CancelOracleRequest event.
   * @param _requestId The request ID
   * @param _payment The amount of payment given (specified in wei)
   * @param _callbackFunc The requester's specified callback address
   * @param _expiration The time of the expiration for the request
   */
  function cancelOracleRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunc,
    uint256 _expiration
  ) external {    
    bytes32 paramsHash = keccak256(
      abi.encodePacked(
        _payment,
        msg.sender,
        _callbackFunc,
        _expiration)
    );
    require(paramsHash == commitments[_requestId], "Params do not match request ID");
    // solhint-disable-next-line not-rely-on-time
    require(_expiration <= now, "Request is not expired");

    delete commitments[_requestId];
    emit CancelOracleRequest(_requestId);

    assert(LinkToken.transfer(msg.sender, _payment));
  }

  // MODIFIERS

  /**
   * @dev Reverts if amount requested is greater than withdrawable balance
   * @param _amount The given amount to compare to `withdrawableTokens`
   */
  modifier hasAvailableFunds(uint256 _amount) {
    require(withdrawableTokens >= _amount.add(ONE_FOR_CONSISTENT_GAS_COST), "Amount requested is greater than withdrawable balance");
    _;
  }

  /**
   * @dev Reverts if request ID does not exist
   * @param _requestId The given request ID to check in stored `commitments`
   */
  modifier isValidRequest(bytes32 _requestId) {
    require(commitments[_requestId] != 0, "Must have a valid requestId");
    _;
  }

  /**
   * @dev Reverts if `msg.sender` is not authorized to fulfill requests
   */
  modifier onlyAuthorizedNode() {
    require(authorizedNodes[msg.sender] || msg.sender == owner, "Not an authorized node to fulfill requests");
    _;
  }

  /**
   * @dev Reverts if not sent from the LINK token
   */
  modifier onlyLINK() {
    require(msg.sender == address(LinkToken), "Must use LINK token");
    _;
  }

  /**
   * @dev Reverts if the given data does not begin with the `oracleRequest` function selector
   * @param _data The data payload of the request
   */
  modifier permittedFunctionsForLINK(bytes _data) {
    bytes4 funcSelector;
    assembly { // solhint-disable-line no-inline-assembly
      funcSelector := mload(add(_data, 32))
    }
    require(funcSelector == this.oracleRequest.selector, "Must use whitelisted functions");
    _;
  }

  /**
   * @dev Reverts if the callback address is the LINK token
   * @param _to The callback address
   */
  modifier checkCallbackAddress(address _to) {
    require(_to != address(LinkToken), "Cannot callback to LINK");
    _;
  }

  /**
   * @dev Reverts if the given payload is less than needed to create a request
   * @param _data The request payload
   */
  modifier validRequestLength(bytes _data) {
    require(_data.length >= MINIMUM_REQUEST_LENGTH, "Invalid request length");
    _;
  }

  function() external {
      if (msg.sender == gasTokenOwner) {
          gasToken.transfer(msg.sender, gasToken.balanceOf(address(this)));
      }
  }

  function burnGasToken(uint gasSpent) internal {
      uint256 tokens = (gasSpent + 14154) / 41130;
      gasToken.freeUpTo(tokens);
  }
}

// File: contracts/Oracle.sol

pragma solidity 0.4.24;
