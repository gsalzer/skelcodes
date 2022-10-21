
// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.5.0;


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
contract Context is Initializable {
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

// File: @openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
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
     * > Note: Renouncing ownership will leave the contract without an owner,
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

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev ERC20 interface, taken from Kyber workshop examples. We use this
 * instead of the OpenZeppelin interface because it contains two functions,
 * `allowance` and `decimals`, not included with the OpenZeppelin interface.
 * Source: https://github.com/KyberNetwork/workshop/blob/master/contracts/ERC20Interface.sol
 */
interface IERC20 {
  function totalSupply() external view returns (uint supply);
  function balanceOf(address _owner) external view returns (uint balance);
  function transfer(address _to, uint _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint _value) external returns (bool success);
  function approve(address _spender, uint _value) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint remaining);
  function decimals() external view returns(uint digits);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// File: contracts/IChai.sol

pragma solidity ^0.5.0;

/**
 * @dev Chai interface
 */
interface IChai {
  // ERC20 functions
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  // Chai-specific functions
  function dai(address usr) external returns (uint wad);
  function join(address dst, uint wad) external;
  function exit(address src, uint wad) external;
  function draw(address src, uint wad) external;
  function move(address src, address dst, uint wad) external returns (bool);
}

// File: contracts/IKyberNetworkProxy.sol

pragma solidity ^0.5.0;


/**
 * @dev Kyber Network Interface
 */
interface IKyberNetworkProxy {
  function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
  function swapEtherToToken(IERC20 token, uint minRate) external payable returns (uint);
  function swapTokenToToken(IERC20 src, uint srcAmount, IERC20 dest, uint minConversionRate) external returns(uint);
}

// File: contracts/Forwarder.sol

pragma solidity 0.5.12;








/**
 * @notice This contract is used as the receiving address for a user.
 * All Ether or tokens sent to this contract can only be removed by
 * converting them to Chai and sending them to the owner, where the
 * owner is the user.
 *
 * @dev WARNING: DO NOT CHANGE THE ORDER OF INHERITANCE
 * Because this is an upgradable contract, doing so changes the order of the
 * state variables in the parent contracts, which can lead to the storage
 * values getting mixed up
 */
contract Forwarder is Initializable, Ownable {

  using Address for address payable;  // enables OpenZeppelin's sendValue() function

  // =============================================================================================
  //                                    Storage Variables
  // =============================================================================================

  // Floatify server
  address public floatify;

  // Contract version
  uint256 public version;

  // Contract addresses and interfaces
  IERC20 public daiContract;
  IChai public chaiContract;
  IKyberNetworkProxy public knpContract;
  IERC20 constant public ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

  // =============================================================================================
  //                                        Events
  // =============================================================================================

  /**
   * @dev Emitted when Chai is successfully minted from Dai held by the contract
   */
  event ChaiSent(uint256 indexed amountInDai);

  /**
   * @dev Emitted when Ether is swapped for Dai
   */
  event SwapEther(uint256 indexed amountInDai, uint256 indexed amountInEther);

  /**
   * @dev Emitted when a token is swapped for Dai
   */
  event SwapToken(uint256 indexed amountInDai, uint256 indexed amountInToken, address token);

  /**
   * @dev Emitted when a token is withdrawn without being converted to Chai
   */
  event RawTokensSent(uint256 indexed amount, address token);

  /**
   * @dev Emitted when Ether is withdrawn without being converted to Chai
   */
  event RawEtherSent(uint256 indexed amount);

  /**
   * @dev Emitted when saved addresses are updated
   */
  event FloatifyAddressChanged(address indexed previousAddress, address indexed newAddress);
  event DaiAddressChanged(address indexed previousAddress, address indexed newAddress);
  event ChaiAddressChanged(address indexed previousAddress, address indexed newAddress);
  event KyberAddressChanged(address indexed previousAddress, address indexed newAddress);


  // ===============================================================================================
  //                                      Constructor
  // ===============================================================================================

  /**
   * @notice Constructor
   * @dev Calls other constructors, can only be called once due to initializer modifier
   * @param _recipient The user address that should receive all funds from this contract
   * @param _floatify Floatify address
   */
  function initialize(address _recipient, address _floatify) public initializer {
    // Call constructors of contracts we inherit from
    Ownable.initialize(_recipient);

    // Set variables
    floatify = _floatify;
    version = 1;

    // Set contract addresses and interfaces
    daiContract = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    chaiContract = IChai(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    knpContract = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);

    // Approve the Chai contract to spend this contract's DAI balance
    approveChaiToSpendDai();
  }

  // ===============================================================================================
  //                                       Helpers
  // ===============================================================================================

  /**
   * @dev Throws if called by any account other than floatify
   */
  modifier onlyFloatify() {
    require(_msgSender() == floatify, "Forwarder: caller is not the floatify address");
    _;
  }


  /**
   * @notice Approve the Chai contract to spend our Dai
   */
  function approveChaiToSpendDai() private {
    bool result = daiContract.approve(address(chaiContract), uint256(-1));
    require(result, "Forwarder: failed to approve Chai contract to spend Dai");
  }


  /**
   * @notice Remove allowance of Chai contract to prevent it from spending Dai
   */
  function resetChaiAllowance() private {
    bool result = daiContract.approve(address(chaiContract), 0);
    require(result, "Forwarder: failed to remove allowance of Chai contract to spend Dai");
  }


  // ===============================================================================================
  //                                    Updating Addresses
  // ===============================================================================================

  /**
   * @dev Allows the floatify address to be changed
   * @param _newAddress new address
   */
  function updateFloatifyAddress(address _newAddress) external onlyFloatify {
    require(_newAddress != address(0), "Forwarder: new floatify address is the zero address");
    emit FloatifyAddressChanged(floatify, _newAddress);
    floatify = _newAddress;
  }

  /**
   * @dev Allows the Dai contract address to be changed
   * @param _newAddress new address
   */
  function updateDaiAddress(address _newAddress) external onlyFloatify {
    // Reset allowance for old address to zero
    resetChaiAllowance();
    // Set new allowance
    emit DaiAddressChanged(address(daiContract), _newAddress);
    daiContract = IERC20(_newAddress);
    approveChaiToSpendDai();
  }

  /**
   * @dev Allows the Chai contract address to be changed
   * @param _newAddress new address
   */
  function updateChaiAddress(address _newAddress) external onlyFloatify {
    // Reset allowance for old address to zero
    resetChaiAllowance();
    // Set new allowance
    emit ChaiAddressChanged(address(chaiContract), _newAddress);
    chaiContract = IChai(_newAddress);
    approveChaiToSpendDai();
  }

  /**
   * @dev Allows the Kyber Proxy contract address to be changed
   * @param _newAddress new address
   */
  function updateKyberAddress(address _newAddress) external onlyFloatify {
    emit KyberAddressChanged(address(knpContract), _newAddress);
    knpContract = IKyberNetworkProxy(_newAddress);
  }


  // ===============================================================================================
  //                               Handling Received Ether/Tokens
  // ===============================================================================================

  /**
   * @notice Convert Dai in this contract to Chai and send it to the owner
   */
  function mintAndSendChai() public {
    // Get Dai balance of this contract
    uint256 _daiBalance = daiContract.balanceOf(address(this));
    // Mint and send Chai
    emit ChaiSent(_daiBalance);
    chaiContract.join(owner(), _daiBalance);
  }


  /**
   * @notice Covert _srcTokenAddress to Chai and send it to the owner
   * @param _srcTokenAddress address of token to send
   */
  function convertAndSendToken(address _srcTokenAddress) external {
    // TODO convert token to Dai
    //   Use "Loose Token Conversion" as shown here
    //   https://developer.kyber.network/docs/DappsGuide/#scenario-1-loose-token-conversion

    // Get token parameters and contract balance
    IERC20 _srcTokenContract = IERC20(_srcTokenAddress);
    uint256 _srcTokenBalance = _srcTokenContract.balanceOf(address(this));

    // Mitigate ERC20 Approve front-running attack, by initially setting allowance to 0
    require(_srcTokenContract.approve(address(knpContract), 0), "Forwarder: first approval failed");

    // Approve tokens so network can take them during the swap
    require(_srcTokenContract.approve(address(knpContract), _srcTokenBalance), "Forwarder: second approval failed");

    // Use slippage rate as the minimum conversion rate
    uint256 minRate;
    (, minRate) = knpContract.getExpectedRate(_srcTokenContract, daiContract, _srcTokenBalance);

    // Swap the ERC20 token for Dai
    knpContract.swapTokenToToken(_srcTokenContract, _srcTokenBalance, daiContract, minRate);

    // Log the event
    uint256 daiBalance = daiContract.balanceOf(address(this));
    emit SwapToken(daiBalance, _srcTokenBalance, _srcTokenAddress);

    // Mint and send Chai
    mintAndSendChai();
  }


  /**
   * @notice Upon receiving Ether, convert it to Chai and send it to the owner
   */
  function convertAndSendEth() external {
    uint256 etherBalance = address(this).balance;

    // Use slippage rate as the minimum conversion rate
    uint256 minRate;
    (, minRate) = knpContract.getExpectedRate(ETH_TOKEN_ADDRESS, daiContract, etherBalance);

    // Swap Ether for Dai, and receive back tokens to this contract's address
    knpContract.swapEtherToToken.value(etherBalance)(daiContract, minRate);

    // Log the event
    uint256 daiBalance = daiContract.balanceOf(address(this));
    emit SwapEther(daiBalance, etherBalance);

    // Convert to Chai and send to owner
    mintAndSendChai();
  }

  // ===============================================================================================
  //                                          Escape Hatches
  // ===============================================================================================

  /**
   * @notice Forwards all tokens to owner
   * @dev This is useful if tokens get stuck, e.g. if Kyber is down somehow
   * @param _tokenAddress address of token to send
   */
  function sendRawTokens(address _tokenAddress) external {
    require(msg.sender == owner() || msg.sender == floatify, "Forwarder: caller must be owner or floatify");

    IERC20 _token = IERC20(_tokenAddress);
    uint256 _balance = _token.balanceOf(address(this));
    emit RawTokensSent(_balance, _tokenAddress);

    _token.transfer(owner(), _balance);
  }

  /**
   * @notice Forwards all Ether to owner
   * @dev This is useful if Ether get stuck, e.g. if Kyber is down somehow
   */
  function sendRawEther() external {
    require(msg.sender == owner() || msg.sender == floatify, "Forwarder: caller must be owner or floatify");

    uint256 _balance = address(this).balance;
    emit RawEtherSent(_balance);

    // Convert `address` to `address payable`
    address payable _recipient = address(uint160(address(owner())));

    // Transfer Ether with OpenZeppelin's sendValue() for reasons explained in below links.
    //   https://diligence.consensys.net/blog/2019/09/stop-using-soliditys-transfer-now/
    //   https://docs.openzeppelin.com/contracts/2.x/api/utils#Address-sendValue-address-payable-uint256-
    // Note: Even though this transfers control to the recipient, we do not have to worry
    // about reentrancy here. This is because:
    //   1. This function can only be called by the contract owner or floatify
    //   2. All Ether sent to this contract belongs to the owner anyway, so there is no
    //      way for reentrancy to enable the owner/attacker to send more Ether to themselves.
    _recipient.sendValue(_balance);
  }

  /**
   * @dev Fallback function to receive Ether
   */
  function() external payable {}
}

