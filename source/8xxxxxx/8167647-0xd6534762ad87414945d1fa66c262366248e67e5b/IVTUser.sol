pragma solidity ^0.5.2;

/**
 * @title IVTUser
 * @dev Contract for upgradeable applications.
 * It handles the creation and upgrading of proxies.
 */
contract IVTUser {

    /// @dev  签名所需最少签名
    uint256 public required;
    /// @dev  owner地址
    address public owner;
    /// @dev  (签名地址==》标志位)
    mapping (address => bool) public signers;
    /// @dev  （交易历史==》标志位）
    mapping (uint256 => bool) public transactions;
    /// @dev  代理地址
    IVTProxyInterface public proxy;

    event Deposit(address _sender, uint256 _value);
  /**
   * @dev Constructor function.
   */
  constructor(address[] memory _signers, IVTProxyInterface _proxy, uint8 _required) public {
    require(_required <= _signers.length && _required > 0 && _signers.length > 0);

    for (uint8 i = 0; i < _signers.length; i++){
        require(_signers[i] != address(0));
        signers[_signers[i]] = true;
    }
    required = _required;
    owner = msg.sender;
    proxy = _proxy;
}

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

/**
 * @dev      充值接口
 * @return   {[null]}
 */
  function() payable external {
      if (msg.value > 0)
          emit Deposit(msg.sender, msg.value);
  }

  /**
   * @dev 向逻辑合约发送请求的通用接口
   * @param _data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function callImpl(bytes calldata _data)  external onlyOwner {
    address implAddress = proxy.getImplAddress();
    implAddress.delegatecall(_data);// 必须用delegatecall
  }

/**
 * @dev      设置Id
 * @param _id _time to set
 */
  function setTransactionId(uint256 _id) public {
    transactions[_id] = true;
  }

/**
 * @dev      获取多签required
 * @return   {[uint256]}
 */
  function getRequired() public view returns (uint256) {
    return required;
  }

/**
 * @dev      是否包含签名者
 * @param _signer _signer to sign
 * @return   {[bool]}
 */
  function hasSigner(address _signer) public view  returns (bool) {
    return signers[_signer];
  }

/**
 * @dev      是否包含交易Id
 * @param _transactionId _transactionTime to get
 * @return   {[bool]}
 */
  function hasTransactionId(uint256 _transactionId) public view returns (bool) {
    return transactions[_transactionId];
  }

}

/**
 * @title IVTProxyInterface
 * @dev Contract for ProxyInterface
 */
contract IVTProxyInterface {
  function getImplAddress() external view returns (address);
}
